def printPattern(pattern)
  pattern.each do |line|
    puts line.join('')
  end
end

def findHorizontalSmudge(pattern)
  height = pattern.length
  rows = pattern

  mirror_line = (0..(height - 2)).find do |line|
    mirror = line + 1
    size = [ mirror, height - line - 1 ].min
    above = rows[(mirror - size)..(mirror - 1)]
    below = rows[(mirror)..(mirror + size - 1)]
    flat_above = above.flatten
    flat_below = below.reverse.flatten
    diffs = flat_above.each_with_index.filter { |c, i| c != flat_below[i] }.count

    diffs == 1
  end

  return mirror_line && mirror_line + 1
end

def findVerticalSmudge(pattern)
  width = pattern.first.length
  cols = width.times.map do |i|
    pattern.map { |line| line[i] }
  end

  mirror_line = (0..(width - 2)).find do |line|
    mirror = line + 1
    size = [ mirror, width - line - 1 ].min
    left = cols[(mirror - size)..(mirror - 1)]
    right = cols[(mirror)..(mirror + size - 1)]
    flat_left = left.flatten
    flat_right = right.reverse.flatten
    diffs = flat_left.each_with_index.filter { |c, i| c != flat_right[i] }.count

    diffs == 1
  end

  return mirror_line && mirror_line + 1
end

def findPerfectHorizontalReflection(pattern)
  height = pattern.length
  rows = pattern

  mirror_line = (0..(height - 2)).find do |line|
    mirror = line + 1
    size = [ mirror, height - line - 1 ].min
    above = rows[(mirror - size)..(mirror - 1)]
    below = rows[(mirror)..(mirror + size - 1)]

    above == below.reverse
  end

  return mirror_line && mirror_line + 1
end

def findPerfectVerticalReflection(pattern)
  width = pattern.first.length
  cols = width.times.map do |i|
    pattern.map { |line| line[i] }
  end

  mirror_line = (0..(width - 2)).find do |line|
    mirror = line + 1
    size = [ mirror, width - line - 1 ].min
    left = cols[(mirror - size)..(mirror - 1)]
    right = cols[(mirror)..(mirror + size - 1)]

    left == right.reverse
  end

  return mirror_line && mirror_line + 1
end

def readPatterns(data, patterns=[])
  idx = data.find_index('')

  pattern = data[0..(idx && idx - 1 || -1)]

  patterns.push(pattern.map { |line| line.chars })

  return idx && readPatterns(data[idx + 1..-1], patterns) || patterns
end

def part1(patterns)
  cols = patterns.map { |p| findPerfectVerticalReflection(p) }.compact.sum
  rows = patterns.map { |p| findPerfectHorizontalReflection(p) }.compact.sum

  rows * 100 + cols
end

def part2(patterns)
  cols = patterns.map { |p| findVerticalSmudge(p) }.compact.sum
  rows = patterns.map { |p| findHorizontalSmudge(p) }.compact.sum

  rows * 100 + cols
end

data = File.open('data').readlines(chomp: true)
patterns = readPatterns(data)

puts "Part 1: #{part1(patterns)}"
puts "Part 2: #{part2(patterns)}"
