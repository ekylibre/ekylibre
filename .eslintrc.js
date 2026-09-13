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
        // `indent`, `quotes` et `semi` ne sont pas déclarées ici : la
        // configuration `prettier` étendue plus haut les désactive exprès, et les
        // rétablir ensuite rouvrait une guerre que `--fix` ne peut pas trancher —
        // `indent` réclamait douze espaces là où prettier en voulait seize, sur
        // le même caractère. Prettier fait foi pour la mise en forme : sa
        // configuration vit dans package.json (tabWidth 4, guillemets simples,
        // largeur 140).
        'linebreak-style': [
            'error',
            'unix'
        ],
        'prettier/prettier': 'error',
        '@typescript-eslint/no-non-null-assertion': 'off'
    }
};
