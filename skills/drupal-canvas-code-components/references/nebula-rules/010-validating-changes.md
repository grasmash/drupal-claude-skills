# Validating changes

After creating or modifying components, always validate your code by running the
`code:fix` script. Make sure to use the right package manager. For example, if
using npm, run the following command:

```bash
npm run code:fix
```

This command runs Prettier and ESLint with auto-fix enabled, ensuring consistent
formatting, common issues, and Drupal Canvas Code Component requirements. Run
this before considering any component work complete.

If the command reports errors that couldn't be automatically fixed, address them
manually in the code and re-run the command until it passes without errors.
