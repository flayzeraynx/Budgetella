# Contributing to FinVault

Thank you for considering contributing to FinVault! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please read it before contributing.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find that the bug has already been reported. If you're unable to find an open issue addressing the problem, open a new one.

When you are creating a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed after following the steps**
- **Explain which behavior you expected to see instead and why**
- **Include screenshots if possible**
- **Include details about your browser and operating system**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When you are creating an enhancement suggestion, please include as many details as possible:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the steps**
- **Describe the current behavior and explain which behavior you expected to see instead**
- **Explain why this enhancement would be useful to most FinVault users**
- **Include screenshots if possible**

### Pull Requests

- Fill in the required template
- Do not include issue numbers in the PR title
- Include screenshots and animated GIFs in your pull request whenever possible
- Follow the TypeScript and React styleguides
- Include thoughtfully-worded, well-structured tests
- Document new code
- End all files with a newline

## Development Setup

1. Fork and clone the repository
2. Install dependencies: `npm install`
3. Start the development server: `npm run dev`

### Project Structure

```
finvault/
├── public/             # Static assets
├── src/
│   ├── components/     # React components
│   │   ├── dashboard/  # Dashboard-related components
│   │   ├── layout/     # Layout components
│   │   ├── settings/   # Settings-related components
│   │   ├── transactions/ # Transaction-related components
│   │   └── ui/         # Reusable UI components
│   ├── context/        # React context providers
│   ├── db/             # Database setup and utilities
│   ├── pages/          # Page components
│   ├── App.tsx         # Main App component
│   ├── index.css       # Global styles
│   └── main.tsx        # Entry point
├── .eslintrc.js        # ESLint configuration
├── index.html          # HTML template
├── package.json        # Project dependencies
├── postcss.config.js   # PostCSS configuration
├── tailwind.config.js  # Tailwind CSS configuration
├── tsconfig.json       # TypeScript configuration
└── vite.config.ts      # Vite configuration
```

## Styleguides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

### TypeScript Styleguide

- Use 2 spaces for indentation
- Use camelCase for variables, properties and function names
- Use PascalCase for types, interfaces, classes, and React components
- Use the type syntax for defining types
- Prefer interfaces over type aliases
- Use async/await instead of Promise chains
- Add trailing commas for cleaner diffs

### React Styleguide

- Use functional components with hooks instead of class components
- Use destructuring props
- Use the useState hook for component state
- Use the useEffect hook for side effects
- Use the useCallback hook for functions passed to child components
- Use the useMemo hook for expensive calculations
- Use the useContext hook for accessing context
- Use the useRef hook for accessing DOM elements

## Testing

- Write tests for all new features and bug fixes
- Run tests before submitting a pull request
- Aim for high test coverage

## Documentation

- Update the README.md with details of changes to the interface
- Update the docs directory with any new documentation
- Comment your code where necessary

## Questions?

Feel free to contact the project maintainers if you have any questions or need help.

Thank you for contributing to FinVault!
