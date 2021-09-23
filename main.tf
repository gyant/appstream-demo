terraform {
  required_version = "~> 1.0.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_appstream_stack" "demo" {
  name         = "appstream-demo"
  description  = "appstream demon"
  display_name = "AppStream Demo"

  # storage_connectors {
  #   connector_type = "GOOGLE_DRIVE"
  # }

  user_settings {
    action     = "CLIPBOARD_COPY_FROM_LOCAL_DEVICE"
    permission = "DISABLED"
  }
  user_settings {
    action     = "CLIPBOARD_COPY_TO_LOCAL_DEVICE"
    permission = "DISABLED"
  }
  user_settings {
    action     = "FILE_UPLOAD"
    permission = "DISABLED"
  }
  user_settings {
    action     = "FILE_DOWNLOAD"
    permission = "DISABLED"
  }
  user_settings {
    action     = "PRINTING_TO_LOCAL_DEVICE"
    permission = "DISABLED"
  }

  application_settings {
    enabled        = true
    settings_group = "SettingsGroup"
  }

  tags = {
    Terraform   = "true"
    Environment = "demo"
  }
}
