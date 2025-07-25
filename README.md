# Fitness Challenge Protocol

A gamified fitness platform built on the Stacks blockchain that enables users to create fitness challenges, submit proof of exercise, and earn rewards for completing health goals.

## Overview

The Fitness Challenge Protocol is a decentralized application that incentivizes healthy lifestyle choices through blockchain-based challenges. Users can create fitness challenges with specific goals, other users can join by paying an entry fee, and successful participants share the reward pool.

## Features

### Core Functionality
- **Create Challenges**: Set up fitness challenges with customizable goals, duration, and rewards
- **Join Challenges**: Participate in existing challenges by paying an entry fee
- **Submit Proof**: Upload exercise proof with verification mechanisms
- **Earn Rewards**: Claim rewards upon successful completion of challenges
- **Verification System**: Optional proof verification by challenge creators or contract owner

### Key Components
- **Challenge Management**: Create, join, and manage fitness challenges
- **Proof Submission**: Submit exercise data with cryptographic proof hashes
- **Reward Distribution**: Automatic reward calculation and distribution
- **Streak Tracking**: Track user performance and completion streaks
- **Emergency Controls**: Owner-only functions for contract maintenance

## Smart Contract Structure

### Data Maps
- `challenges`: Stores challenge information and metadata
- `participants`: Tracks participant progress and status
- `exercise-proofs`: Records submitted exercise proofs
- `participant-rewards`: Maintains user reward statistics

### Key Functions

#### Public Functions
- `create-challenge`: Create a new fitness challenge
- `join-challenge`: Join an existing challenge
- `submit-exercise-proof`: Submit proof of exercise completion
- `verify-exercise-proof`: Verify submitted proofs (for authorized users)
- `claim-reward`: Claim rewards after successful challenge completion
- `end-challenge`: End a challenge early (creator only)

#### Read-Only Functions
- `get-challenge`: Retrieve challenge information
- `get-participant-info`: Get participant status and progress
- `is-challenge-active`: Check if a challenge is currently active
- `calculate-reward-share`: Calculate potential reward for a participant

## Technical Specifications

- **Language**: Clarity (Stacks blockchain)
- **Total Lines**: ~300 lines
- **Entry Fee**: Configurable STX amount per challenge
- **Reward System**: Pool-based distribution among successful participants
- **Verification**: Optional proof verification system
- **Duration**: Block-based challenge duration system

## Usage Examples

### Creating a Challenge
```clarity
(create-challenge 
  u"30-Day Running Challenge"
  u"Run a total of 100 miles in 30 days"
  "running"
  u100  ;; 100 miles target
  u4320 ;; ~30 days in blocks
  u1000000 ;; 1 STX entry fee
  u20  ;; max 20 participants
  true ;; verification required
)
```

### Joining a Challenge
```clarity
(join-challenge u1) ;; Join challenge ID 1
```

### Submitting Proof
```clarity
(submit-exercise-proof 
  u1 ;; challenge ID
  "running"
  u5 ;; 5 miles completed
  0x1234... ;; proof hash
)
```

## Security Features

- **Entry Fee Protection**: Fees are held in contract until challenge completion
- **Verification System**: Optional proof verification for challenge integrity
- **Owner Controls**: Emergency functions for contract maintenance
- **Participant Validation**: Comprehensive checks for all user interactions

## Installation & Deployment

1. Clone the repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet`
3. Navigate to project directory
4. Run tests: `clarinet test`
5. Deploy to testnet: `clarinet deploy --testnet`

## Contract Address
(To be updated after deployment)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

## Contact

For questions or support, please contact the development team.

---

*Built with love for the Stacks ecosystem*