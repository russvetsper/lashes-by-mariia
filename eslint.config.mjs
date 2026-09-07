/**
 * Debugging:
 *   https://eslint.org/docs/latest/use/configure/debug
 *  ----------------------------------------------------
 *
 *   Print a file's calculated configuration
 *
 *     npx eslint --print-config path/to/file.js
 *
 *   Inspecting the config
 *
 *     npx eslint --inspect-config
 *
 */

import globals from 'globals';
import js from '@eslint/js';
import { defineConfig, globalIgnores } from 'eslint/config';

import ember from 'eslint-plugin-ember/recommended';
import WarpDrive from 'eslint-plugin-warp-drive/recommended';
import eslintConfigPrettier from 'eslint-config-prettier';
import qunit from 'eslint-plugin-qunit';
import n from 'eslint-plugin-n';

import babelParser from '@babel/eslint-parser/experimental-worker';

const esmParserOptions = {
  ecmaFeatures: { modules: true },
  ecmaVersion: 'latest',
};

export default defineConfig([
  globalIgnores(['dist/', 'coverage/', '!**/.*']),

  js.configs.recommended,

  eslintConfigPrettier,

  ember.configs.base,

  ember.configs.gjs,

  ...WarpDrive,

  /**
   * ESLint linter options
   */
  {
    linterOptions: {
      reportUnusedDisableDirectives: 'error',
    },
  },

  /**
   * JavaScript files
   */
  {
    files: ['**/*.js'],
    languageOptions: {
      parser: babelParser,
    },
  },

  /**
   * JavaScript and Glimmer files
   */
  {
    files: ['**/*.{js,gjs}'],
    languageOptions: {
      parserOptions: esmParserOptions,
      globals: {
        ...globals.browser,
      },
    },
  },

  /**
   * QUnit tests
   */
  {
    ...qunit.configs.recommended,
    files: ['tests/**/*-test.{js,gjs}'],
    plugins: {
      qunit,
    },
  },

  /**
   * CJS Node files
   */
  {
    ...n.configs['flat/recommended-script'],
    files: ['**/*.cjs', 'config/**/*.js'],
    plugins: {
      n,
    },
    languageOptions: {
      sourceType: 'script',
      ecmaVersion: 'latest',
      globals: {
        ...globals.node,
      },
    },
  },

  /**
   * Supabase Edge Functions
   *
   * These files run in Deno, not Ember/Warp Drive.
   */
  {
    files: ['supabase/functions/**/*.ts'],
    rules: {
      'warp-drive/no-external-request-patterns': 'off',
    },
    languageOptions: {
      sourceType: 'module',
      ecmaVersion: 'latest',
      globals: {
        ...globals.browser,
        Deno: 'readonly',
      },
    },
  },

  /**
   * ESM Node files
   */
  {
    ...n.configs['flat/recommended-module'],
    files: ['**/*.mjs'],
    plugins: {
      n,
    },
    languageOptions: {
      sourceType: 'module',
      ecmaVersion: 'latest',
      parserOptions: esmParserOptions,
      globals: {
        ...globals.node,
      },
    },
  },
]);
