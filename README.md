# EcoFuture Lab Smart Contract

A blockchain-based platform for creating environmental prediction markets and research funding mechanisms on the Stacks blockchain.

## Overview

EcoFuture Lab is a smart contract that enables users to create environmental research studies, contribute funding based on outcome predictions, and participate in a decentralized research ecosystem. The contract facilitates scientific research funding through prediction markets focused on environmental outcomes.

## Features

- **Research Study Creation**: Scientists can create new environmental research studies with hypotheses
- **Prediction-Based Contributions**: Users can contribute STX tokens based on their prediction of research outcomes
- **Configurable Parameters**: Platform administrators can adjust contribution limits and study periods
- **Decentralized Governance**: Transfer of eco-scientist privileges for platform management

## Contract Architecture

### Constants

The contract defines 16 error constants for robust error handling:
- `ERROR-INVALID-STUDY-TIME`: Invalid study timeline
- `ERROR-RESEARCH-INACTIVE`: Research study is not active
- `ERROR-RESEARCH-COMPLETED`: Research study already completed
- `ERROR-INVALID-CONTRIBUTION`: Invalid contribution amount
- `ERROR-RESEARCH-NOT-EXISTS`: Research study does not exist
- `ERROR-INSUFFICIENT-GRANTS`: Insufficient STX balance
- `ERROR-UNAUTHORIZED`: Unauthorized access
- And more...

### Validation Constants

- `MAX-BLOCKS-UNTIL-STUDY`: Maximum ~1 year (52,560 blocks)
- `MIN-BLOCKS-UNTIL-STUDY`: Minimum ~1 day (144 blocks)
- `MAX-BLOCKS-UNTIL-COMPLETION`: Maximum ~2 years (105,120 blocks)
- `MIN-HYPOTHESIS-LENGTH`: Minimum 10 characters for hypothesis

### Data Structures

#### Research Studies Map
```clarity
{
  study-id: uint,
  hypothesis: string-ascii 256,
  environmental-result: optional bool,
  contribution-deadline: uint,
  completion-cutoff: uint,
  lead-researcher: principal
}
```

#### Research Contributions Map
```clarity
{
  study-id: uint,
  contributor: principal,
  contribution-amount: uint,
  outcome-hypothesis: bool
}
```

## Public Functions

### `create-research-study`
Create a new environmental research study.

**Parameters:**
- `hypothesis` (string-ascii 256): Research hypothesis description
- `contribution-deadline` (uint): Block height deadline for contributions

**Returns:** Study ID

**Validations:**
- Hypothesis length between 10-256 characters
- Valid study timeline (1 day to 1 year)
- Valid completion period (up to 2 years after contribution deadline)

### `place-research-contribution`
Contribute STX tokens to a research study based on outcome prediction.

**Parameters:**
- `study-id` (uint): ID of the research study
- `outcome-hypothesis` (bool): Prediction of research outcome
- `contribution-amount` (uint): Amount of STX to contribute

**Validations:**
- Valid study ID
- Contribution amount within limits
- Research study still active
- Sufficient STX balance

### `set-research-completion-period`
Set the research completion period (eco-scientist only).

**Parameters:**
- `new-period` (uint): New completion period in blocks

**Restrictions:**
- Only eco-scientist can call
- Period must be between 1,000 and 52,560 blocks

### `set-minimum-contribution-amount`
Set minimum contribution amount (eco-scientist only).

**Parameters:**
- `new-amount` (uint): New minimum contribution amount

**Restrictions:**
- Only eco-scientist can call
- Must be less than maximum contribution amount
- Maximum limit of 1,000,000

### `set-maximum-contribution-amount`
Set maximum contribution amount (eco-scientist only).

**Parameters:**
- `new-amount` (uint): New maximum contribution amount

**Restrictions:**
- Only eco-scientist can call
- Must be greater than minimum contribution amount
- Must be at least 1,000 and at most 1,000,000,000,000

### `transfer-eco-scientist`
Transfer eco-scientist privileges to another principal.

**Parameters:**
- `new-scientist` (principal): New eco-scientist principal

**Restrictions:**
- Only current eco-scientist can call
- Cannot transfer to self

## Read-Only Functions

### `get-eco-scientist`
Returns the current eco-scientist principal.

## Configuration Variables

- `platform-name`: "EcoFuture Lab"
- `research-completion-period`: 10,000 blocks (default)
- `minimum-contribution-amount`: 10 STX (default)
- `maximum-contribution-amount`: 1,000,000 STX (default)

## Usage Examples

### Creating a Research Study
```clarity
(contract-call? .ecofuture-lab create-research-study 
  "Rising sea levels will increase coastal erosion by 15% in the next 5 years"
  u150000) ;; Contribution deadline in blocks
```

### Contributing to Research
```clarity
(contract-call? .ecofuture-lab place-research-contribution 
  u1        ;; Study ID
  true      ;; Outcome prediction
  u100)     ;; Contribution amount
```

### Updating Configuration (Eco-scientist only)
```clarity
(contract-call? .ecofuture-lab set-minimum-contribution-amount u50)
```

## Security Features

- **Input Validation**: Comprehensive validation for all inputs
- **Access Control**: Role-based access for administrative functions
- **Balance Checks**: Ensures sufficient STX balance before contributions
- **State Validation**: Prevents operations on completed or expired studies
- **Overflow Protection**: Checks for contribution amount limits

## Deployment

The contract is written in Clarity for the Stacks blockchain. Deploy using:
1. Stacks CLI
2. Stacks Explorer
3. Hiro Platform

## Testing

Recommended test scenarios:
- Create research studies with various parameters
- Test contribution limits and validations
- Verify access control for administrative functions
- Test edge cases for timing and amounts
