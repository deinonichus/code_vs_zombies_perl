use strict;
use warnings;
#use diagnostics;
use 5.20.1;

use List::Util;

select(STDOUT); $| = 1; # DO NOT REMOVE

# Save humans, destroy zombies!

# Improvements:
# Calculate player speed
# Calculate zombie speed
# Move in gun_range to closest zombie
# Which human is the farthest from zombies?
# Which human is the closest to the player?
# Which human is the closest to zombies but still safeable?

my $tokens;
my $gun_range = 2320;
my $zombie_range = 400;
my $player_speed = 1000; # units per turn
my $zombie_speed = 400; # units per turn

my @humans = qx{};
my @zombies = qx{};
my %distance_player_to_humans = qx{};
my %distance_player_to_zombies = qx{};
my %distance_humans_to_zombies = qx{};
my %safeable_humans = qx{};

my $destination_x = 0;
my $destination_y = 0;

my $nearest_human_x = 0;
my $nearest_human_y = 0;

my $nearest_zombie_x = 0;
my $nearest_zombie_y = 0;

my $most_endangered_human_x = 0;
my $most_endangered_human_y = 0;

sub getDistance {
    my $distance = 0;
    my @coordinates = @_;

    my $point_a_x = $coordinates[0][0];
    my $point_a_y = $coordinates[0][1];
    my $point_b_x = $coordinates[1][0];
    my $point_b_y = $coordinates[1][1];

    return $distance;
}

# game loop
while (1) {
    @humans = qx{};
    @zombies = qx{};
    %distance_player_to_humans = qx{};
    %distance_player_to_zombies = qx{};
    %distance_humans_to_zombies = qx{};


    # Locations
    # =================================================

    # Player
    chomp($tokens=<STDIN>);
    my ($player_x, $player_y) = split(/ /,$tokens);
    #print STDERR "Meine Koordinaten: x$player_x, y$player_y\n";

    # Humans
    chomp(my $human_count = <STDIN>);
    #print STDERR "Anzahl Menschen: $human_count\n";
    for my $i (0..$human_count-1) {
        chomp($tokens=<STDIN>);
        my ($human_id, $human_x, $human_y) = split(/ /,$tokens);

        #print STDERR "Mensch Koordinaten Mensch $human_id: x$human_x, y$human_y\n";

        my @human_coordinates = qx{};
        push @human_coordinates, $human_x;
        push @human_coordinates, $human_y;
        push @humans, [ @human_coordinates ];

        $safeable_humans{$human_id} = 1;
    }

    # Zombies
    chomp(my $zombie_count = <STDIN>);
    #print STDERR "Anzahl Zombies: $zombie_count\n";
    for my $i (0..$zombie_count-1) {
        chomp($tokens=<STDIN>);
        my ($zombie_id, $zombie_x, $zombie_y, $zombie_xnext, $zombie_ynext) = split(/ /,$tokens);

        #print STDERR "Zombie Koordinaten Zombie $zombie_id: x$zombie_x, y$zombie_y\n";

        my @coordinates = qx{};
        push @coordinates, $zombie_x;
        push @coordinates, $zombie_y;
        push @zombies, [ @coordinates ];
    }


    # Calculations
    # =================================================

    # Player to Humans
    for my $human (0 .. $#humans) {
        my $distance = 0;
        $distance = sqrt((($humans[$human][0]-$player_x)**2)+(($humans[$human][1]-$player_y)**2));
        $distance_player_to_humans{$human} = $distance;
    }
    for my $human (keys %distance_player_to_humans) {
        #print STDERR "distance from player to human $human: $distance_player_to_humans{$human}\n";
    }
    foreach my $distance (sort {$a <=> $b} values %distance_player_to_humans) {
        #print STDERR "distance from player to human : $distance\n";
    }
    #print STDERR "distance from player to human 0 $distance_player_to_humans{0}\n";

    # Player to Zombies
    for my $zombie (0 .. $#zombies) {
        my $distance = 0;
        $distance = sqrt((($zombies[$zombie][0]-$player_x)**2)+(($zombies[$zombie][1]-$player_y)**2));
        $distance_player_to_zombies{$zombie} = $distance;
    }
    for my $zombie (keys %distance_player_to_zombies) {
        #print STDERR "distance from player to zombie $zombie: $distance_player_to_zombies{$zombie}\n";
    }
    foreach my $distance (sort {$a <=> $b} values %distance_player_to_zombies) {
        #print STDERR "distance from player to zombie: $distance\n";
    }
    #print STDERR "distance from player to zombie 0 $distance_player_to_zombies{0}\n";

    # Humans to Zombies
    for my $human (0 .. $#humans) {
        my %zombie_distances = qx{};
        for my $zombie (0 .. $#zombies) {
            my $distance = 0;
            $distance = sqrt((($zombies[$zombie][0]-$humans[$human][0])**2)+(($zombies[$zombie][1]-$humans[$human][1])**2));
            $zombie_distances{$zombie} = $distance;
        }
        $distance_humans_to_zombies{$human} = {%zombie_distances};
    }
    # For every human print distance to every zombie
    for my $human (keys %distance_humans_to_zombies) {
        for my $zombie (0 .. $#zombies) {
            #print STDERR "distance from human $human to zombie $zombie: $distance_humans_to_zombies{$human}{$zombie}\n";
        }
    }
    # For every human print distance to every zombie sorted
    # Evaluate which human can be safed
    foreach my $human ( sort { keys %{$distance_humans_to_zombies{$b}} <=> keys %{$distance_humans_to_zombies{$a}} }
        keys %distance_humans_to_zombies )
    {
        print STDERR "human $human\n";
        for my $zombie ( sort keys %{ $distance_humans_to_zombies{$human} } ) {
            my $distance_to_zombie = 0;
            my $distance_to_player = 0;
            my $dead_in_turns = 0;
            my $safed_in_turns = 0;
            $distance_to_zombie = $distance_humans_to_zombies{$human}{$zombie};
            $distance_to_player = $distance_player_to_humans{$human};
            $dead_in_turns = ($distance_to_zombie-$zombie_range)/$zombie_speed;
            $safed_in_turns = ($distance_player_to_zombies{$zombie}-$gun_range)/$player_speed;
            print STDERR "dead in turns: $dead_in_turns\n";
            print STDERR "safed in turns: $safed_in_turns\n";
            if ($dead_in_turns <= $safed_in_turns ) {
                $safeable_humans{$human} = 0;
                print STDERR "Human $human is LOST\n";
            }
            print STDERR "distance to zombie $zombie: $distance_to_zombie\n";
        }
        print STDERR "\n";
    }
    foreach my $distance (sort {$a <=> $b} values %distance_humans_to_zombies) {
        #print STDERR "distance from human to zombie: $distance\n";
    }
    #print STDERR "distance from human 0 to zombie 0 $distance_humans_to_zombies{0}{0}\n";

    foreach my $human (keys %safeable_humans) {
        #print STDERR "human $human safe? $safeable_humans{$human}\n";
    }

    # Evaluate the closest human which can be safed
    foreach my $human ( sort { keys %{$distance_player_to_humans{$b}} <=> keys %{$distance_player_to_humans{$a}} }
        keys %distance_player_to_humans )
    {
        print STDERR "distance to human $human is $distance_player_to_humans{$human}\n";
        if ($safeable_humans{$human}) {
            print STDERR "Human is safeable\n";
            last;
        }
        print STDERR "Human is NOT safeable\n";
    }

    # Range to Zombie 0
    my $distance_to_zombie_0 = sqrt((($zombies[0][0]-$player_x)**2)+(($zombies[0][1]-$player_y)**2));
    my $distance_to_human_0 = sqrt((($humans[0][0]-$player_x)**2)+(($humans[0][1]-$player_y)**2));
    if ($distance_to_zombie_0 <= $gun_range) {
        $destination_x = $player_x;
        $destination_y = $player_y;
        next;
    }

    # Movement
    # =================================================
    if ($player_x != $humans[0][0] && $player_y != $humans[0][1]) {
        $destination_x = $humans[0][0];
        $destination_y = $humans[0][1];
    }
    else {
        #sqrt($zombies[0][0])
        #$destination_x =
        #$destination_y =
    }

    # Write an action using print
    # To debug: print STDERR "Debug messages...\n";

    print "$destination_x $destination_y\n"; # Your destination coordinates
}
