module MoneyValue
  extend ActiveSupport::Concern

  class_methods do
    def monetize_attributes(*attrs)
      attrs.each do |attr|
        define_method(:"#{attr}=") do |value|
          return super(nil) unless value.present?
          coerced = BigDecimal(value.to_s)
          super(coerced)
        rescue ArgumentError, TypeError
          super(value)
        end
      end
    end
  end
end
