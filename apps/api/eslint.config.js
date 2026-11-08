const tseslint = require('typescript-eslint');

module.exports = tseslint.config(
  { ignores: ['dist/', 'node_modules/', 'prisma/', 'eslint.config.js'] },
  ...tseslint.configs.recommended,
  {
    files: ['src/**/*.ts', 'test/**/*.ts'],
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/consistent-type-imports': 'error',
    },
  },
);
