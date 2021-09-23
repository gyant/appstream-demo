resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "appstream-demo"
        Terraform = "True"
        Environment = "Demo"
    }
}

resource "aws_vpc_dhcp_options" "dhcp_options_set" {
    domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "dhcp_options_assoc" {
    vpc_id          = aws_vpc.vpc.id
    dhcp_options_id = aws_vpc_dhcp_options.dhcp_options_set.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_nat_gateway" "nat" {
  subnet_id = aws_subnet.public.id
  allocation_id = aws_eip.nat_eip.id
  tags = {
    Name = "gw NAT"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "nat_eip" {
  vpc      = true
}

resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "nacl"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Public"
  }
}

resource "aws_subnet" "firewall" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Firewall"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public_igw" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
  depends_on                = [aws_route_table.public]
}

resource "aws_route" "public_firewall" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "10.0.2.0/24"
  vpc_endpoint_id = tolist(aws_networkfirewall_firewall.firewall.firewall_status[0].sync_states)[0].attachment[0].endpoint_id
  depends_on                = [aws_route_table.public]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "private_firewall" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  vpc_endpoint_id = tolist(aws_networkfirewall_firewall.firewall.firewall_status[0].sync_states)[0].attachment[0].endpoint_id
  depends_on                = [aws_route_table.private]
}

resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "fw_nat" {
  route_table_id            = aws_route_table.firewall.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
  depends_on                = [aws_route_table.firewall]
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "firewall" {
  subnet_id      = aws_subnet.firewall.id
  route_table_id = aws_route_table.firewall.id
}

resource "aws_networkfirewall_firewall" "firewall" {
  name                = "demofirewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.mainfwpolicy.arn
  vpc_id              = aws_vpc.vpc.id
  subnet_mapping {
    subnet_id = aws_subnet.firewall.id
  }
}

resource "aws_networkfirewall_firewall_policy" "mainfwpolicy" {
  name = "mainfwpolicy"
  firewall_policy {
    stateless_default_actions = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allowgmail.arn
    } 
  }
}

resource "aws_networkfirewall_logging_configuration" "firewall_logging" {
  firewall_arn = aws_networkfirewall_firewall.firewall.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

resource "aws_cloudwatch_log_group" "firewall" {
  name = "Firewall"
}

resource "aws_networkfirewall_rule_group" "allowgmail" {
  capacity = 100
  name     = "allowgmail"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = ["mail.google.com"]
      }
    }
  }
}