module.exports = {
    'env': {
        'node': true,
        'browser': true,
        'es2020': true
    },
    "ignorePatterns": [ "coverage/**"],
    'extends': [
        'eslint:recommended',
        'plugin:vue/base',
        'prettier',
        'prettier/vue',
    ],
    'overrides': [
      {
        'files': ['**/**/*.ts'],
        'plugins': [
          '@typescript-eslint',
        ],
        'extends': ['eslint:recommended', 'plugin:@typescript-eslint/recommended'],
        'parser': '@typescript-eslint/parser',
        'parserOptions': {
          'project': ['./tsconfig.json'],
        },
      },
    ],
    'parserOptions': {
        'ecmaVersion': 11,
        'sourceType': 'module'
    },
    'plugins': [
        'prettier',
        'vue',
    ],
    'rules': {
        'indent': [
            'error',
            4
        ],
        'linebreak-style': [
            'error',
            'unix'
        ],
        'quotes': [
            'error',
            'single'
        ],
        'semi': [
            'error',
            'always'
        ],
        'prettier/prettier': 'error',
        '@typescript-eslint/no-non-null-assertion': 'off'
    }
};
