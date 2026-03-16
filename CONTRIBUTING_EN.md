# Contribution Guidelines

Thank you for your interest in the Google IAP Ultimate project! We welcome contributions in various forms.

## 📋 Ways to Contribute

### 1. Report Bugs
If you find a bug, please report it through the following methods:

**Bug Report Template:**
```markdown
## Problem Description
Clearly describe the issue encountered

## Reproduction Steps
1. Step 1
2. Step 2
3. ...

## Expected Behavior
Describe the expected normal behavior

## Actual Behavior
Describe the actual erroneous behavior

## Environment Information
- Godot Version:
- Plugin Version:
- Operating System:
- Device Information:

## Screenshots/Logs
If relevant screenshots or logs are available, please attach them
```

### 2. Feature Requests
If you have new feature ideas, please submit a feature request:

**Feature Request Template:**
```markdown
## Feature Description
Describe in detail the feature you wish to add

## Use Cases
Explain in what scenarios this feature would be useful

## Possible Implementation
If you have implementation ideas, describe them here

## Alternative Solutions
Are there existing alternative solutions
```

### 3. Code Contributions
If you want to contribute code, please follow this process:

## 🔧 Development Environment Setup

### Prerequisites
- Godot Engine 4.0+
- Git
- Basic GDScript knowledge

### Setting Up Development Environment

1. **Fork Repository**
   ```bash
   # Fork project to your GitHub account
   # Then clone to local
   git clone https://github.com/your-username/google-iap-ultimate.git
   cd google-iap-ultimate
   ```

2. **Create Development Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Install Dependencies**
   ```bash
   # Ensure Godot project is properly set up
   # Open project and enable plugin
   ```

## 📝 Code Standards

### GDScript Coding Standards

**Naming Conventions:**
- Class Names: `PascalCase` (e.g., `GoogleIAP`)
- Function Names: `snake_case` (e.g., `init_iap_service`)
- Variable Names: `snake_case` (e.g., `user_config`)
- Constant Names: `SCREAMING_SNAKE_CASE` (e.g., `MAX_RETRY_COUNT`)

**Code Format:**
```gdscript
# Correct format
extends Node

# Class variables
var class_variable: String = "default"

# Signal definitions
signal purchase_completed(product_id: String)

func _ready() -> void:
    # Function implementation
    pass

# Private functions use underscore prefix
func _private_method() -> void:
    pass
```

### Documentation Standards

**Function Documentation:**
```gdscript
## Initialize IAP service
##
## @param config_path: Configuration file path
## @return: Whether initialization was successful
func init_iap_service(config_path: String) -> bool:
    # Implementation...
    return true
```

### Commit Message Standards

**Commit Message Format:**
```
type(scope): short description

Detailed description (optional)

Closes #IssueNumber (optional)
```

**Type Descriptions:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation update
- `style`: Code formatting changes
- `refactor`: Code refactoring
- `test`: Testing related
- `chore`: Build tools or dependency updates

**Example:**
```
feat(sku): Add SKU batch import functionality

- Support CSV format batch import
- Add data validation mechanism
- Optimize import performance

Closes #123
```

## 🧪 Testing Requirements

### Unit Tests
All new features must include unit tests:

```gdscript
# Create corresponding test files in test/ directory
extends GutTest

func test_sku_validation():
    var iap = GoogleIAP.new()
    assert_true(iap.validate_sku("valid_product_id"))
    assert_false(iap.validate_sku(""))
```

### Integration Tests
Important features require integration testing:
- Multi-platform compatibility testing
- End-to-end process testing
- Performance testing

## 🔍 Code Review Process

### Submitting Pull Request

1. **Ensure Code Quality**
   - Pass all tests
   - Comply with coding standards
   - Include necessary documentation

2. **Create PR**
   ```markdown
   ## Change Description
   Describe in detail the changes in this PR
   
   ## Related Issues
   Associated issue numbers
   
   ## Test Results
   Describe testing situation and results
   
   ## Screenshots
   If there are UI changes, attach screenshots
   ```

3. **Code Review**
   - Requires review by at least 1 core maintainer
   - Merge after review approval

## 📚 Documentation Contributions

### Documentation Types
- **Usage Documentation**: User guides, tutorials
- **Technical Documentation**: API references, architecture explanations
- **Development Documentation**: Contribution guides, development instructions

### Documentation Standards
- Use Markdown format
- Include clear table of contents
- Provide actual code examples
- Maintain synchronization between Chinese and English versions

## 🏆 Contributor Rewards

### Contributor List
All contributors will be listed in the project contributor list.

### Special Contributions
Major contributors may receive:
- Project maintainer permissions
- Special acknowledgment identifiers
- Priority technical support

## ❓ Frequently Asked Questions

### Q: How do I start contributing?
A: Start with simple bug fixes or documentation improvements, then move to feature development after familiarizing with the project structure.

### Q: How long does code review take?
A: Usually 1-3 business days, complex changes may take longer.

### Q: How to contact the maintenance team?
A: Contact through GitHub Issues or Discord community.

## 📞 Contact Information

- **GitHub Issues**: Problem reporting and discussion
- **Discord Community**: Real-time communication and technical support
- **Email Support**: Enterprise-level technical support

---

**Thank you for your contribution!** 🎉

---

*Last Updated: 2026-03-16*  
*Maintainer: zyuanhua*