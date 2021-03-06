# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # This cop checks for redundant `begin` blocks.
      #
      # Currently it checks for code like this:
      #
      # @example
      #
      #   # bad
      #   def redundant
      #     begin
      #       ala
      #       bala
      #     rescue StandardError => e
      #       something
      #     end
      #   end
      #
      #   # good
      #   def preferred
      #     ala
      #     bala
      #   rescue StandardError => e
      #     something
      #   end
      #
      #   # bad
      #   begin
      #     do_something
      #   end
      #
      #   # good
      #   do_something
      #
      #   # bad
      #   # When using Ruby 2.5 or later.
      #   do_something do
      #     begin
      #       something
      #     rescue => ex
      #       anything
      #     end
      #   end
      #
      #   # good
      #   # In Ruby 2.5 or later, you can omit `begin` in `do-end` block.
      #   do_something do
      #     something
      #   rescue => ex
      #     anything
      #   end
      #
      #   # good
      #   # Stabby lambdas don't support implicit `begin` in `do-end` blocks.
      #   -> do
      #     begin
      #       foo
      #     rescue Bar
      #       baz
      #     end
      #   end
      class RedundantBegin < Base
        extend AutoCorrector

        MSG = 'Redundant `begin` block detected.'

        def on_def(node)
          return unless node.body&.kwbegin_type?

          register_offense(node.body)
        end
        alias on_defs on_def

        def on_block(node)
          return if target_ruby_version < 2.5

          return if node.send_node.lambda_literal?
          return if node.braces?
          return unless node.body&.kwbegin_type?

          register_offense(node.body)
        end

        def on_kwbegin(node)
          return if node.parent&.assignment?
          return if node.parent&.post_condition_loop?

          first_child = node.children.first
          return if first_child.rescue_type? || first_child.ensure_type?

          register_offense(node)
        end

        private

        def register_offense(node)
          add_offense(node.loc.begin) do |corrector|
            corrector.remove(node.loc.begin)
            corrector.remove(node.loc.end)
          end
        end
      end
    end
  end
end
