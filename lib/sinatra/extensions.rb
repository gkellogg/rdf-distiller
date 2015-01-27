require 'sinatra/assetpack'

# From https://github.com/rstacruz/sinatra-assetpack/issues/35#issuecomment-7457048
# Workaround problem with shared assets in different subclasses
module Sinatra::AssetPack
  def assets(&block)
    @@options ||= Options.new(self, &block)
    self.assets_initialize!  if block_given?
    @@options
  end
end

