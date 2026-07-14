import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import reactHooks from 'eslint-plugin-react-hooks'
import prettier from 'eslint-config-prettier'
import globals from 'globals'

export default tseslint.config(
  {
    // Dependencies, build output, and Rails-owned directories.
    ignores: ['node_modules/**', 'public/**', 'vendor/**', 'tmp/**', 'coverage/**', 'log/**'],
  },

  // Browser code: the React frontend.
  {
    files: ['app/frontend/**/*.{ts,tsx}'],
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    plugins: { 'react-hooks': reactHooks },
    languageOptions: {
      globals: globals.browser,
      parserOptions: { ecmaFeatures: { jsx: true } },
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      // Intentionally unused args and vars are marked with a leading underscore.
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      // Warn, don't fail: every fetch-on-mount hook trips this rule, and silencing it
      // means restructuring how pages load data. Tracked as follow-up work rather than
      // bundled into the PR that introduces linting.
      'react-hooks/set-state-in-effect': 'warn',
    },
  },

  // Ambient type declarations: empty interfaces and `any` are how module
  // augmentation is written, so the rules against them do not apply.
  {
    files: ['app/frontend/**/*.d.ts'],
    rules: {
      '@typescript-eslint/no-empty-object-type': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': 'off',
    },
  },

  // Test files and fixtures also touch Node APIs.
  {
    files: ['app/frontend/**/*.test.{ts,tsx}', 'app/frontend/test/**/*.ts'],
    languageOptions: {
      globals: { ...globals.browser, ...globals.node },
    },
  },

  // Tooling config that runs in Node.
  {
    files: ['*.js', '*.ts'],
    extends: [js.configs.recommended],
    languageOptions: {
      globals: globals.node,
    },
  },

  // Leaves formatting to Prettier by switching off stylistic rules: must stay last.
  prettier
)
