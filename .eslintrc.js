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
        'plugin:@typescript-eslint/recommended'
    ],
    'parserOptions': {
        'ecmaVersion': 11,
        'parser': '@typescript-eslint/parser',
        'sourceType': 'module'
    },
    'plugins': [
        'prettier',
        'vue',
        '@typescript-eslint'
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
