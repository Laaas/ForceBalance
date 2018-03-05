# About

This mod is an alternative to Bof's JoinTeam.

# How it works

It uses [this](https://moultano.wordpress.com/2014/08/04/a-skill-ranking-system-for-natural-selection-2/)
to calculate the win probabilities.

The plugin can then use this information to "force" balance.

# Configuration options

All configuration options are stored in config://shine/plugins/ForceBalance.json

## InformPlayer

Whether to inform the player about the current status on the right side of their screen when
they are in the ready room.

## ForcePlayer

Whether to force the player to join the preferred team

## AnythingBetterIsAcceptable

Allow the player to join both teams, if it would improve skill
in both cases, instead of just allowing the best case.

## UseMapBalance

Don't use this

## MaxPlayers

The max amount of players allowed in playing teams
