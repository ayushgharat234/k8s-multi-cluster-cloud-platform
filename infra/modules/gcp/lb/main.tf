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

# 2. SSL Policy — reject legacy TLS 1.0/1.1 and weak ciphers
resource "google_compute_ssl_policy" "default" {
  name            = "${var.env_name}-ssl-policy"
  project         = var.project_id
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

# 3. Google-managed SSL Certificate (auto-provisioned; requires DNS pointing at the global IP)
resource "google_compute_managed_ssl_certificate" "default" {
  name    = "${var.env_name}-cert"
  project = var.project_id

  managed {
    domains = [var.domain]
  }
}

# 4. Backend Service (GKE Network Endpoint Groups)
resource "google_compute_backend_service" "default" {
  name        = "${var.env_name}-backend"
  project     = var.project_id
  protocol    = "HTTP" # TLS is terminated at the LB; internal traffic stays HTTP
  port_name   = "http"
  timeout_sec = 30

  dynamic "backend" {
    for_each = var.neg_ids
    content {
      group = backend.value
    }
  }

  health_checks = [google_compute_health_check.default.id]

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# 5. Health Check
resource "google_compute_health_check" "default" {
  name    = "${var.env_name}-health-check"
  project = var.project_id

  http_health_check {
    port         = 80
    request_path = "/healthz"
  }
}

# 6. URL Map
resource "google_compute_url_map" "default" {
  name            = "${var.env_name}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.default.id
}

# 7. HTTPS Proxy (with SSL policy and managed certificate)
resource "google_compute_target_https_proxy" "default" {
  name             = "${var.env_name}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
  ssl_policy       = google_compute_ssl_policy.default.id
}

# 8. HTTPS Forwarding Rule (the live entry point — port 443)
resource "google_compute_global_forwarding_rule" "https" {
  name       = "${var.env_name}-https-rule"
  project    = var.project_id
  ip_address = google_compute_global_address.default.address
  port_range = "443"
  target     = google_compute_target_https_proxy.default.id
}

# 9. HTTP → HTTPS redirect (port 80 returns 301)
resource "google_compute_url_map" "http_redirect" {
  name    = "${var.env_name}-http-redirect"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  name    = "${var.env_name}-http-redirect-proxy"
  project = var.project_id
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  name       = "${var.env_name}-http-redirect-rule"
  project    = var.project_id
  ip_address = google_compute_global_address.default.address
  port_range = "80"
  target     = google_compute_target_http_proxy.redirect.id
}
