# Demo Environment Bootstrap

Unfortunately, it's not currently possible to automate all things AppStream with terraform due to limitations with the aws provider. It's possible to define a stack but not users, fleets, or stack-fleet associations.

The terraform sets up a network with 2 private subnets and a public with a single NAT Gateway as well as an AppStream stack definition.

### Bootstrap

1. `terraform init`
1. `terraform apply`
1. Open up AWS UI and navigate to AppStream.
1. Click `Fleets`
1. Click `Create Fleet`
1. Go through fleet creation wizard. Associate the fleet with the VPC created with our terraform and choose the private subnets for both subnets. (default sg is okay)
1. Click `Stacks`
1. Click our `appstream-demo` stack and go to Actions -> Associate Fleet.
1. Select the fleet we just created and associate it with the terraform-created stack.
1. Click `User Pool`
1. Click `Create User`
1. Create yourself a test user with an email you're able to access.
1. Select the user we just created in the AWS Console.
1. Actions -> Assign Stack - Assign the `appstream-demo` stack with this user.
1. Check your email for the login invitation.
1. Login
1. Use Appstream.