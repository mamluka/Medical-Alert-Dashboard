require_relative '../lib/billing/billing'

billing = Billing.new.get_billing

$stdout.puts billing