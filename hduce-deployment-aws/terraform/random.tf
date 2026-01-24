# ============================================
# RANDOM RESOURCES
# For unique naming
# ============================================

resource "random_id" "instance_suffix" {
  byte_length = 4
}
