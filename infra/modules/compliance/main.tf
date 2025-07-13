resource "aws_config_configuration_recorder_status" "config" {
  name       = "${var.project}-${var.env}-config-recorder"
  is_enabled = true
}

resource "aws_config_conformance_pack" "compliance" {
  name = "${var.project}-${var.env}-conformance-pack"
  
  template_body = file("${path.module}/conformance-pack.yaml")

  depends_on = [aws_config_configuration_recorder_status.config]
}
