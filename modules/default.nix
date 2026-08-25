# Compatibility shim: old `imports = [ ../modules ]` keeps working.
# New code should use `modules/nixos` directly or via `roles/nixos/*`.
{
  imports = [ ./nixos ];
}
