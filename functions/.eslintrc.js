module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*",       // Ignora archivos compilados
    "/generated/**/*", // Ignora archivos generados
  ],
  plugins: ["@typescript-eslint", "import"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    // Descomenta si quieres reglas de Google, pero suelen ser MUY estrictas en Windows:
    // "google",
    // "plugin:import/errors",
    // "plugin:import/warnings",
    // "plugin:import/typescript",
  ],
  rules: {
    // ✅ Relajamos reglas que te estaban bloqueando el deploy
    "linebreak-style": "off",             // CRLF/LF (Windows)
    "max-len": "off",
    "object-curly-spacing": "off",
    "comma-dangle": "off",
    "block-spacing": "off",
    "arrow-parens": "off",
    "curly": "off",
    "no-multi-spaces": "off",
    "quote-props": "off",
    "require-jsdoc": "off",
    "valid-jsdoc": "off",

    // ✅ TypeScript
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/no-non-null-assertion": "off",
    "@typescript-eslint/no-unused-vars": [
      "warn",
      { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }
    ],

    // ✅ Import resolver
    "import/no-unresolved": "off",

    // ✅ Estética básica (puedes ajustarlas si quieres)
    "quotes": ["warn", "double", { "avoidEscape": true }],
    "indent": ["warn", 2, { "SwitchCase": 1 }],
  },
};
