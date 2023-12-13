def expandMap(map, galaxies, size)
  expandedGalaxies = galaxies.map(&:dup)
  offset = 0

  map.each_with_index do |l, y|
    if l.all?('.')
      expandedGalaxies.filter { |g| g[1] > y + offset }.each { |g |g[1] += size }
      offset += size
    end
  end

  offset = 0

  map[0].length.times.each do |x|
    col = map.map { |l| l[x] }

    if col.all?('.')
      expandedGalaxies.filter { |g| g[0] > x + offset }.each { |g| g[0] += size }
      offset += size
    end
  end

  return expandedGalaxies
end

def findGalaxies(map)
  galaxies = []

  map.each_with_index do |row, y|
    row.each_with_index do |c, x|
      galaxies.push([x, y]) if c == '#'
    end
  end

  return galaxies
end

def computeGalaxyPairs(galaxies)
  return galaxies.each_with_index.flat_map do |g, i|
    galaxies[(i + 1)..-1].map { |g2| [g, g2] }
  end
end

map = File.open('data').readlines(chomp: true).map { |l| l.chars }
galaxies = findGalaxies(map)
expandedGalaxies = expandMap(map, galaxies, 1000000 - 1)

res = computeGalaxyPairs(expandedGalaxies).sum do |g1, g2|
  (g1[0] - g2[0]).abs + (g1[1] - g2[1]).abs
end

p res
