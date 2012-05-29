#
# This should generate colors for a CSS dashboard theme.
#
# Some theory:
#
# I use HSL form since it is much, much more convenient, essentially,
# to generate colors around the spectrum (or variants of color families),
# all you have to do (programmatically) is travel on a circle (divided to 360deg).
# Really like slicing a Pizza.
#
# Below I chose to generate 10 colors, which provides enough spacing on slices
# so that colors are highly contrasted yet still share a gradual rainbow theme.
#
# You might want to tweak the ordering to create a more cheerful theme for you own
# dashboard.
#

NUM_COLORS = 10

interval = 360/NUM_COLORS 
i = 190
j = 1

# Figure out what a full circle from the start would be
max = i + 360

# Iterate until we make a full circle
while i < max

# Since we can get higher than 360, find the right value
color = i % 360

  puts ".h-col-#{j}{ stroke: hsl(#{color}, 100%, 50%); fill: hsl(#{color}, 100%, 50%);}"
  j +=1
  i += interval
end

