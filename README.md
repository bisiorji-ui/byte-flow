# ByteFlow Smart Contract Documentation

## Overview
This Clarity smart contract implements the core functionality for ByteFlow, a blockchain-powered roguelike dungeon crawler with NFT characters that evolve through gameplay.

## Features

### 1. Character NFT System
- **Mint Characters**: Create unique character NFTs with DNA hashing
- **Transfer Characters**: Trade characters between players
- **Character Attributes**: Each character has level, strength, agility, and intelligence stats

### 2. Evolution Mechanics
- Characters can be evolved by spending in-game tokens
- Each evolution increases level and selected stat (+5 bonus)
- Evolution count tracked for each character

### 3. Play-to-Earn Economy
- **Dungeon Completion**: Earn tokens by completing dungeons
- **Governance Tokens**: Receive 10% of dungeon rewards as governance tokens
- **Staking**: Stake characters for passive income based on blocks staked

### 4. Character Staking
- Stake tokens using your character
- Earn rewards proportional to stake amount and duration
- Unstake anytime to claim rewards

## Contract Functions

### Public Functions

#### `mint-character`
```clarity
(mint-character (name (string-ascii 50)) (dna-hash (string-ascii 64)))
```
Creates a new character NFT with initial stats.

**Parameters:**
- `name`: Character name (max 50 characters)
- `dna-hash`: Unique DNA identifier (64 characters)

**Returns:** Token ID of newly minted character

#### `transfer-character`
```clarity
(transfer-character (token-id uint) (recipient principal))
```
Transfers character ownership to another player.

#### `evolve-character`
```clarity
(evolve-character (token-id uint) (stat-type (string-ascii 20)))
```
Evolves a character by spending tokens to increase stats.

**Stat Types:**
- `"strength"` - Increases strength by 5
- `"agility"` - Increases agility by 5
- `"intelligence"` - Increases intelligence by 5

**Cost:** 100 tokens (default)

#### `complete-dungeon`
```clarity
(complete-dungeon (token-id uint))
```
Marks a dungeon as completed and awards tokens.

**Rewards:**
- 50 tokens (default)
- 5 governance tokens (10% of reward)

#### `stake-character`
```clarity
(stake-character (token-id uint) (amount uint))
```
Stakes tokens using your character for passive income.

#### `unstake-character`
```clarity
(unstake-character (token-id uint))
```
Unstakes and claims accumulated rewards.

**Reward Formula:** `(stake-amount × blocks-staked) / 1000`

### Read-Only Functions

#### `get-character`
Returns all character data for a given token ID.

#### `get-character-metadata`
Returns character name and DNA hash.

#### `get-user-balance`
Returns token balance for a user.

#### `get-governance-balance`
Returns governance token balance for a user.

#### `get-character-owner`
Returns the owner of a character.

#### `get-staked-info`
Returns staking information for a character.

### Admin Functions (Owner Only)

#### `set-evolution-cost`
Updates the cost to evolve a character.

#### `set-dungeon-reward`
Updates the reward for completing a dungeon.

#### `grant-tokens`
Grants tokens to a user (for testing/admin purposes).

## Data Structures

### Character
```clarity
{
    owner: principal,
    level: uint,
    strength: uint,
    agility: uint,
    intelligence: uint,
    evolution-count: uint,
    dungeons-completed: uint,
    created-at: uint
}
```

### Character Metadata
```clarity
{
    name: (string-ascii 50),
    dna-hash: (string-ascii 64)
}
```

## Error Codes

- `u100`: Owner-only operation
- `u101`: Not token owner
- `u102`: Character not found
- `u103`: Insufficient balance
- `u104`: Already exists

## Usage Example

```clarity
;; 1. Mint a new character
(contract-call? .byteflow mint-character "DragonSlayer" "abc123...")

;; 2. Complete a dungeon to earn tokens
(contract-call? .byteflow complete-dungeon u0)

;; 3. Evolve your character
(contract-call? .byteflow evolve-character u0 "strength")

;; 4. Stake for passive income
(contract-call? .byteflow stake-character u0 u50)

;; 5. Check character stats
(contract-call? .byteflow get-character u0)
```

## Deployment Notes

1. Deploy contract to Stacks blockchain
2. Contract deployer becomes the owner
3. Initial evolution cost: 100 tokens
4. Initial dungeon reward: 50 tokens
5. Use `grant-tokens` to distribute initial tokens to players

## Security Features

- Owner validation for admin functions
- Token ownership verification for character operations
- Balance checks before spending
- Immutable character creation timestamps
- Protected staking mechanisms

## Future Enhancements

This simple implementation can be extended with:
- Cross-chain bridges for character portability
- IPFS integration for metadata storage
- Advanced DNA evolution algorithms
- Multiplayer dungeon mechanics
- Marketplace for character trading
- Guild/team functionality
