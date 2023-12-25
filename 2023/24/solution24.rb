require_relative "../../lib/base"
require "z3"

# Solution for the 2023 day 24 puzzle
# https://adventofcode.com/2023/day/24
#
# Needed help on part 2 of this one. I had the right idea, but I didn't know how to solve the equations.
class AoC::Year2023::Solution24 < Base
  def part1(test_area: nil)
    hailstones = parse_input
    test_area ||= {
      min_x: 2e14,
      max_x: 4e14,
      min_y: 2e14,
      max_y: 4e14
    }
    count_intersections(hailstones, test_area)
  end

  def part2
    solve_with_z3
  end

  def parse_input
    input_lines.map do |line|
      position, velocity = line.chomp.split(" @ ").map { |s| s.split(", ").map(&:to_i) }
      {position: position, velocity: velocity}
    end
  end

  def find_intersection(pos1:, v1:, pos2:, v2:)
    x1_0, y1_0 = pos1
    vx1, vy1 = v1
    x2_0, y2_0 = pos2
    vx2, vy2 = v2

    result = {}

    if vx1 == 0 && vy1 == 0
      result[:status] = :stationary_line_1
      return result
    elsif vx2 == 0 && vy2 == 0
      result[:status] = :stationary_line_2
      return result
    end

    if vy1 * vx2 == vy2 * vx1
      result[:status] = ((x1_0 - x2_0) * vy1 == (y1_0 - y2_0) * vx1) ? :coincident : :parallel
      return result
    end

    t2 = (vx1 * y2_0 - vy1 * x2_0 + vy1 * x1_0 - vx1 * y1_0).to_f / (vy1 * vx2 - vy2 * vx1)

    t1 = if vx1 != 0
      (x2_0 + vx2 * t2 - x1_0) / vx1
    else
      (y2_0 + vy2 * t2 - y1_0) / vy1
    end

    intersection_point = [x2_0 + vx2 * t2, y2_0 + vy2 * t2]
    result.merge(status: :intersected, intersection_point:, t1:, t2:)
  end

  def intersects?(h1, h2, test_area)
    pos1 = h1[:position]
    v1 = h1[:velocity]
    pos2 = h2[:position]
    v2 = h2[:velocity]

    intersection = find_intersection(pos1: pos1, v1: v1, pos2: pos2, v2: v2)

    case intersection[:status]
    when :intersected
      x, y = intersection[:intersection_point]
      t1 = intersection[:t1]
      t2 = intersection[:t2]
      x >= test_area[:min_x] && x <= test_area[:max_x] &&
        y >= test_area[:min_y] && y <= test_area[:max_y] &&
        t1 >= 0 && t2 >= 0
    else
      false
    end
  end

  def count_intersections(hailstones, test_area)
    hailstones.combination(2).sum do |h1, h2|
      intersects?(h1, h2, test_area) ? 1 : 0
    end
  end

  def solve_with_z3
    # needed help from the thread - learned about Z3 and how to use it from there.
    hailstones = parse_input.take(3)
    solver = Z3::Solver.new
    px, py, pz, vx, vy, vz = %w[px py pz vx vy vz].map { Z3.Int(_1) } # position and velocity of our rock

    hailstones.each_with_index do |hail, i|
      t = Z3.Int("t#{i}")
      solver.assert(t >= 0)
      solver.assert(px + vx * t == hail[:position][0] + hail[:velocity][0] * t)
      solver.assert(py + vy * t == hail[:position][1] + hail[:velocity][1] * t)
      solver.assert(pz + vz * t == hail[:position][2] + hail[:velocity][2] * t)
    end

    return solver.model[px + py + pz].to_i if solver.check == :sat

    raise "No solution found"
  end
end

if __FILE__ == $PROGRAM_NAME
  solution = AoC::Year2023::Solution24.new
  solution.run
end
