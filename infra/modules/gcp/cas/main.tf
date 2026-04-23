terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ── Root CA Pool ──────────────────────────────────────────────────────────────
# Holds the self-signed root CA. DEVOPS tier: no per-cert fees, flat pool pricing.
# Restricted to CA-only issuance via issuance_policy so it cannot issue
# end-entity certs directly.

resource "google_privateca_ca_pool" "root" {
  name     = "${var.env_name}-root-pool"
  location = var.region
  project  = var.project_id
  tier     = "DEVOPS"

  publishing_options {
    publish_ca_cert = true
    publish_crl     = false
  }

  issuance_policy {
    maximum_lifetime = "315360000s" # 10 years — matches root CA lifetime
  }
}

# ── Root CA (self-signed, RSA 4096) ───────────────────────────────────────────
# Trust anchor for the entire CA hierarchy. RSA 4096 for wide client compatibility.
# max_issuer_path_length = 2 allows: root → sub → end-entity (two hops max).

resource "google_privateca_certificate_authority" "root" {
  certificate_authority_id = "${var.env_name}-root-ca"
  location                 = var.region
  project                  = var.project_id
  pool                     = google_privateca_ca_pool.root.name
  deletion_protection      = var.deletion_protection

  config {
    subject_config {
      subject {
        organization = var.organization
        common_name  = "${var.env_name} Root CA"
      }
    }
    x509_config {
      ca_options {
        is_ca                  = true
        max_issuer_path_length = 2
      }
      key_usage {
        base_key_usage {
          cert_sign         = true
          crl_sign          = true
          digital_signature = true
        }
        extended_key_usage {}
      }
    }
  }

  key_spec {
    algorithm = "RSA_PKCS1_4096_SHA256"
  }

  lifetime = "315360000s" # 10 years
  type     = "SELF_SIGNED"
}

# ── Subordinate CA Pool ───────────────────────────────────────────────────────
# Single pool containing all three subordinate CAs. Issuance policy enforces
# a 30-day maximum cert lifetime and baseline key usage for end-entity certs.

resource "google_privateca_ca_pool" "subordinate" {
  name     = "${var.env_name}-sub-pool"
  location = var.region
  project  = var.project_id
  tier     = "DEVOPS"

  publishing_options {
    publish_ca_cert = true
    publish_crl     = false
  }

  issuance_policy {
    maximum_lifetime = "2592000s" # 30 days — short-lived end-entity certs
    baseline_values {
      ca_options {
        is_ca = false
      }
      key_usage {
        base_key_usage {
          digital_signature = true
          key_encipherment  = true
        }
        extended_key_usage {
          server_auth = true
          client_auth = true
        }
      }
    }
  }
}

# ── Subordinate CA 1: Mesh mTLS ───────────────────────────────────────────────
# Issues short-lived certs for Istio/ASM workloads (both server_auth and
# client_auth). EC P256 matches the default Istio cert algorithm.
# When ASM custom CA integration is enabled, point ASM to this pool.

resource "google_privateca_certificate_authority" "mesh" {
  certificate_authority_id = "${var.env_name}-mesh-ca"
  location                 = var.region
  project                  = var.project_id
  pool                     = google_privateca_ca_pool.subordinate.name
  deletion_protection      = var.deletion_protection

  config {
    subject_config {
      subject {
        organization = var.organization
        common_name  = "${var.env_name} Mesh CA"
      }
    }
    x509_config {
      ca_options {
        is_ca                  = true
        max_issuer_path_length = 0 # leaf-issuing only — cannot chain further
      }
      key_usage {
        base_key_usage {
          cert_sign         = true
          crl_sign          = true
          digital_signature = true
        }
        extended_key_usage {
          server_auth = true
          client_auth = true
        }
      }
    }
  }

  key_spec {
    algorithm = "EC_P256_SHA256"
  }

  lifetime = "94608000s" # 3 years
  type     = "SUBORDINATE"

  subordinate_config {
    # Triggers automatic CSR signing by the root CA within CAS.
    # GCP signs the subordinate CA cert and activates it; no manual step required.
    certificate_authority = google_privateca_certificate_authority.root.name
  }

  depends_on = [google_privateca_certificate_authority.root]
}

# ── Subordinate CA 2: Internal TLS ────────────────────────────────────────────
# Issues server-only certs for internal services (webhooks, internal APIs,
# ingress controllers). Separate from mesh-ca so revocation scope is isolated.

resource "google_privateca_certificate_authority" "internal_tls" {
  certificate_authority_id = "${var.env_name}-internal-tls-ca"
  location                 = var.region
  project                  = var.project_id
  pool                     = google_privateca_ca_pool.subordinate.name
  deletion_protection      = var.deletion_protection

  config {
    subject_config {
      subject {
        organization = var.organization
        common_name  = "${var.env_name} Internal TLS CA"
      }
    }
    x509_config {
      ca_options {
        is_ca                  = true
        max_issuer_path_length = 0
      }
      key_usage {
        base_key_usage {
          cert_sign         = true
          crl_sign          = true
          digital_signature = true
          key_encipherment  = true
        }
        extended_key_usage {
          server_auth = true
        }
      }
    }
  }

  key_spec {
    algorithm = "EC_P256_SHA256"
  }

  lifetime = "94608000s" # 3 years
  type     = "SUBORDINATE"

  subordinate_config {
    certificate_authority = google_privateca_certificate_authority.root.name
  }

  depends_on = [google_privateca_certificate_authority.root]
}

# ── Subordinate CA 3: Workload Identity ───────────────────────────────────────
# Issues client-auth certs for SPIFFE/SVID workload identity, CI runners,
# and cross-service authentication where mTLS is not mesh-managed.

resource "google_privateca_certificate_authority" "workload" {
  certificate_authority_id = "${var.env_name}-workload-ca"
  location                 = var.region
  project                  = var.project_id
  pool                     = google_privateca_ca_pool.subordinate.name
  deletion_protection      = var.deletion_protection

  config {
    subject_config {
      subject {
        organization = var.organization
        common_name  = "${var.env_name} Workload CA"
      }
    }
    x509_config {
      ca_options {
        is_ca                  = true
        max_issuer_path_length = 0
      }
      key_usage {
        base_key_usage {
          cert_sign         = true
          crl_sign          = true
          digital_signature = true
        }
        extended_key_usage {
          client_auth = true
        }
      }
    }
  }

  key_spec {
    algorithm = "EC_P256_SHA256"
  }

  lifetime = "94608000s" # 3 years
  type     = "SUBORDINATE"

  subordinate_config {
    certificate_authority = google_privateca_certificate_authority.root.name
  }

  depends_on = [google_privateca_certificate_authority.root]
}

# ── IAM: CI service account can request certs from the subordinate pool ───────

resource "google_privateca_ca_pool_iam_member" "ci_cert_requester" {
  ca_pool   = google_privateca_ca_pool.subordinate.id
  role      = "roles/privateca.certificateRequester"
  member    = "serviceAccount:${var.ci_service_account_email}"
  location  = var.region
  project   = var.project_id
}
