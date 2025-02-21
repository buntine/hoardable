# frozen_string_literal: true

module Hoardable
  # Provides temporal version awareness to +has_many+ relationships.
  module HasMany
    extend ActiveSupport::Concern

    # An +ActiveRecord+ extension that allows looking up {VersionModel}s by +hoardable_id+ as
    # if they were {SourceModel}s when using {Hoardable#at}.
    module HasManyExtension
      def scope
        @scope ||= hoardable_scope
      end

      private def hoardable_scope
        if Thread.current[:hoardable_at]
          (hoardable_id = @association.owner.hoardable_id)
          @association.scope.rewhere(@association.reflection.foreign_key => hoardable_id)
        else
          @association.scope
        end
      end
    end
    private_constant :HasManyExtension

    class_methods do
      def has_many(*args, &block)
        options = args.extract_options!
        hoardable_option = options.delete(:hoardable)
        cascade_option = options.delete(:untrash)
        options[:extend] = Array(options[:extend]).push(HasManyExtension) if hoardable_option

        reflections = super(*args, **options, &block)

        if cascade_option
          reflections[args.first].instance_variable_set(:@cascade_untrash, true)
        end

        return unless hoardable_option

        # This hack is needed to force Rails to not use any existing method cache so that the
        # {HasManyExtension} scope is always used when using {Hoardable.at}.
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{args.first}
            if Thread.current[:hoardable_at]
              super.extending
            else
              super
            end
          end
        RUBY
      end
    end
  end
  private_constant :HasMany
end
