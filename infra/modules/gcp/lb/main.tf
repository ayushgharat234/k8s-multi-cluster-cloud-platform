terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# 1. Global Static IP
resource "google_compute_global_address" "default" {
  name    = "${var.env_name}-global-ip"
  project = var.project_id
}

# 2. SSL Policy — used only when domain is set
resource "google_compute_ssl_policy" "default" {
  count           = var.domain != "" ? 1 : 0
  name            = "${var.env_name}-ssl-policy"
  project         = var.project_id
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

# 3. Certificate Manager — only when domain is provided
resource "google_certificate_manager_dns_authorization" "default" {
  count   = var.domain != "" ? 1 : 0
  name    = "${var.env_name}-dns-auth"
  project = var.project_id
  domain  = var.domain
}

resource "google_certificate_manager_certificate" "default" {
  count   = var.domain != "" ? 1 : 0
  name    = "${var.env_name}-cert"
  project = var.project_id
  managed {
    domains            = [var.domain]
    dns_authorizations = [google_certificate_manager_dns_authorization.default[0].id]
  }
}

resource "google_certificate_manager_certificate_map" "default" {
  count   = var.domain != "" ? 1 : 0
  name    = "${var.env_name}-cert-map"
  project = var.project_id
}

resource "google_certificate_manager_certificate_map_entry" "default" {
  count        = var.domain != "" ? 1 : 0
  name         = "${var.env_name}-cert-map-entry"
  project      = var.project_id
  map          = google_certificate_manager_certificate_map.default[0].name
  certificates = [google_certificate_manager_certificate.default[0].id]
  hostname     = var.domain
}

# 4. Health Check — Frontend (port 80)
resource "google_compute_health_check" "frontend" {
  name    = "${var.env_name}-frontend-hc"
  project = var.project_id
  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

# 5. Health Check — Payment (port 8080)
resource "google_compute_health_check" "payment" {
  name    = "${var.env_name}-payment-hc"
  project = var.project_id
  http_health_check {
    port         = 8080
    request_path = "/health"
  }
}

# 6. Backend Service — Frontend
resource "google_compute_backend_service" "frontend" {
  name        = "${var.env_name}-frontend-backend"
  project     = var.project_id
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  dynamic "backend" {
    for_each = var.frontend_neg_ids
    content {
      group                 = backend.value
      balancing_mode        = "RATE"
      max_rate_per_endpoint = 100
    }
  }

  health_checks = [google_compute_health_check.frontend.id]

  dynamic "iap" {
    for_each = var.iap_client_id != "" ? [1] : []
    content {
      oauth2_client_id     = var.iap_client_id
      oauth2_client_secret = var.iap_client_secret
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_iap_web_backend_service_iam_binding" "frontend_iap_users" {
  count               = var.iap_client_id != "" && length(var.iap_members) > 0 ? 1 : 0
  project             = var.project_id
  web_backend_service = google_compute_backend_service.frontend.name
  role                = "roles/iap.httpsResourceAccessor"
  members             = var.iap_members
}

# 7. Backend Service — Payment
resource "google_compute_backend_service" "payment" {
  name        = "${var.env_name}-payment-backend"
  project     = var.project_id
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  dynamic "backend" {
    for_each = var.payment_neg_ids
    content {
      group                 = backend.value
      balancing_mode        = "RATE"
      max_rate_per_endpoint = 100
    }
  }

  health_checks = [google_compute_health_check.payment.id]

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# 8. URL Map — /api/payment/* → payment, everything else → frontend
resource "google_compute_url_map" "default" {
  name            = "${var.env_name}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.frontend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "app-paths"
  }

  path_matcher {
    name            = "app-paths"
    default_service = google_compute_backend_service.frontend.id

    path_rule {
      paths   = ["/api/payment", "/api/payment/*"]
      service = google_compute_backend_service.payment.id
    }
  }
}

# ── NO-DOMAIN MODE: plain HTTP ────────────────────────────────────────────────
# Used when var.domain == "" (no TLS — suitable for demo/IP-only access)

resource "google_compute_target_http_proxy" "direct" {
  count   = var.domain == "" ? 1 : 0
  name    = "${var.env_name}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "http_direct" {
  count      = var.domain == "" ? 1 : 0
  name       = "${var.env_name}-http-rule"
  project    = var.project_id
  ip_address = google_compute_global_address.default.address
  port_range = "80"
  target     = google_compute_target_http_proxy.direct[0].id
}

# ── DOMAIN MODE: HTTPS with Certificate Manager + HTTP→HTTPS redirect ─────────

resource "google_compute_target_https_proxy" "default" {
  count           = var.domain != "" ? 1 : 0
  name            = "${var.env_name}-https-proxy"
  project         = var.project_id
  url_map         = google_compute_url_map.default.id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.default[0].id}"
  ssl_policy      = google_compute_ssl_policy.default[0].id
}

resource "google_compute_global_forwarding_rule" "https" {
  count      = var.domain != "" ? 1 : 0
  name       = "${var.env_name}-https-rule"
  project    = var.project_id
  ip_address = google_compute_global_address.default.address
  port_range = "443"
  target     = google_compute_target_https_proxy.default[0].id
}

resource "google_compute_url_map" "http_redirect" {
  count   = var.domain != "" ? 1 : 0
  name    = "${var.env_name}-http-redirect"
  project = var.project_id
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  count   = var.domain != "" ? 1 : 0
  name    = "${var.env_name}-http-redirect-proxy"
  project = var.project_id
  url_map = google_compute_url_map.http_redirect[0].id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  count      = var.domain != "" ? 1 : 0
  name       = "${var.env_name}-http-redirect-rule"
  project    = var.project_id
  ip_address = google_compute_global_address.default.address
  port_range = "80"
  target     = google_compute_target_http_proxy.redirect[0].id
}

# ── DNS (only when dns_zone_dns_name is set) ───────────────────────────────────

resource "google_dns_managed_zone" "default" {
  count       = var.dns_zone_dns_name != "" ? 1 : 0
  name        = "${var.env_name}-zone"
  project     = var.project_id
  dns_name    = var.dns_zone_dns_name
  description = "OpsNexus public zone"
  dnssec_config {
    state = "on"
  }
}

resource "google_dns_record_set" "lb_a" {
  count        = var.dns_zone_dns_name != "" ? 1 : 0
  name         = "${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.default[0].name
  project      = var.project_id
  rrdatas      = [google_compute_global_address.default.address]
}

resource "google_dns_record_set" "cert_cname" {
  count        = var.dns_zone_dns_name != "" && var.domain != "" ? 1 : 0
  name         = google_certificate_manager_dns_authorization.default[0].dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.default[0].dns_resource_record[0].type
  ttl          = 300
  managed_zone = google_dns_managed_zone.default[0].name
  project      = var.project_id
  rrdatas      = [google_certificate_manager_dns_authorization.default[0].dns_resource_record[0].data]
}
