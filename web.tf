resource "aws_launch_configuration" "lc1" {
  name          = "launch config"
  image_id      = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  security_groups = ["${aws_security_group.lbasg.id}"]
  associate_public_ip_address = "true"
  user_data      = "${file("test.sh")}"

lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "asg" {
  name                      = "asg"
  max_size                  = "${var.max_size}"
  min_size                  = "${var.min_size}"
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = "${var.desired_capacity}"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.lc1.name}"
  vpc_zone_identifier       = ["${aws_subnet.pub1.id}" , "${aws_subnet.pub2.id}"]
  target_group_arns    = ["${aws_lb_target_group.tg1.arn}"]  

  tag {
    key                 = "Name"
    value               = "test"
    propagate_at_launch = true
  }
}

