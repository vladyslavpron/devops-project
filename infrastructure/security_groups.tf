
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ecs-${local.name}"
}

resource "aws_security_group_rule" "ecs_http_ingress" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "TCP"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
  name   = local.name
}

resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_http_egress_http" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

