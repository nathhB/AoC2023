def expandMap(map)
  expandedMap = []

  map.each do |l|
    expandedMap.push(l.dup)
    expandedMap.push(l.dup) if l.all? '.'
  end

  x = 0

  map[0].length.times.each do |i|
    if map.all? { |l| l[i] == '.' }
      expandedMap.each do |line|
        line.insert(x, '.')
      end

      x += 1
    end

    x += 1
  end

  return expandedMap
end

def computeGalaxyPairs(map)
  galaxies = []

  map.each_with_index do |row, y|
    row.each_with_index do |c, x|
      galaxies.push([x, y]) if c == '#'
    end
  end

  return galaxies.each_with_index.flat_map do |g, i|
    galaxies[(i + 1)..-1].map { |g2| [g, g2] }
  end
end

map = File.open('data').readlines(chomp: true).map { |l| l.chars }
expandedMap = expandMap(map)

res = computeGalaxyPairs(expandedMap).sum do |g1, g2|
  (g1[0] - g2[0]).abs + (g1[1] - g2[1]).abs
end

p res
