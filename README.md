Micro Savings Circle (ROSCA) Smart Contract

Overview

This contract implements a Rotating Savings and Credit Association (ROSCA), commonly known as a micro-savings circle.
A group of participants ("members") contribute a fixed STX amount each round, and during every round, one member receives the entire pot. Once every member has received their payout, the circle is completed.

The contract ensures:

Fixed weekly (or periodic) contributions

Automatic round progression

Guaranteed payout order

Correct tracking of contributions and recipients

Transparent error handling and round validation

Key Features
✔ Membership Management

Users can join before the circle starts.

Membership limit is enforced.

Member index determines payout order.

✔ Circle Lifecycle

Circle can only be started by the contract owner.

Once started, no new members can join.

Each round has one pot payout to a predetermined recipient.

✔ Contributions

Each member contributes the exact contribution-amount (default 1 STX).

Contributions are tracked per round.

No double contributions within the same round.

✔ Payout / Distribution

Only the contract owner can trigger a pot distribution.

All members must have contributed before payout.

Payout transfers all STX held by the contract to the designated round recipient.

Recipient is marked as having received their payout and the circle advances to the next round.

Data Structures
Data Variables
Variable	Description
contribution-amount	Required amount each member must contribute per round
max-members	Maximum allowed number of members
member-count	Current number of members
current-round	Current active round number (1-based)
circle-started	Whether the circle has begun
total-rounds	Equal to total members once started
Maps

members: Stores each member’s index, join round, and payout status

round-contributions: Tracks contributions by member and round

member-by-index: Reverse lookup for payout sequence

Contract Flow
1. Joining the Circle
(join-circle)


Conditions:

Circle must not have started

User must not already be a member

Circle must not be full

Effect:

Member is assigned an index

Count of members increments

2. Starting the Circle
(start-circle)


Only the contract owner can call this.

Effects:

circle-started becomes true

current-round set to 1

total-rounds set to member-count

3. Contributing
(contribute)


Conditions:

Circle must be started

Round must not exceed total rounds

Member must not have contributed this round

Member must exist

Effects:

STX transferred from member → contract

Contribution logged

4. Distributing the Pot
(distribute-pot)


Only the owner can trigger distribution.

Conditions:

All members have contributed

Recipient has not previously received a payout

Effects:

Contract balance transferred to the current round’s recipient

Recipient marked as having received

Round increments

Read-Only Functions

Useful for UI integrations and monitoring:

get-contribution-amount

get-max-members

get-member-count

get-current-round

is-circle-started

get-member-info

has-contributed-this-round

get-current-recipient

get-pot-balance

is-member

Error Codes
Error Code	Meaning
u100	Owner-only action
u101	Caller is not a member
u102	Already a member
u103	Circle capacity reached
u104	Invalid contribution amount
u105	Already contributed this round
u106	Not all members have contributed
u107	Member already received payout
u108	Circle not started
u109	Circle already completed
Security Considerations

Only the owner can start the circle or distribute pot funds.

Contribution and payout logic is atomic and validated.

No external contract calls besides STX transfers.

Prevents double contributions and double payouts.