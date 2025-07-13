locals {
  workspace_config = {
    dev = {
      instance_type = "t3.micro"
      asg_min_size  = 1
      asg_max_size  = 2
    }
    staging = {
      instance_type = "t3.small"
      asg_min_size  = 2
      asg_max_size  = 4
    }
    prod = {
      instance_type = "t3.medium"
      asg_min_size  = 3
      asg_max_size  = 6
    }
  }
}
