# frozen_string_literal: true

module Standweb
  class Web < Sinatra::Base
    namespace '/member/?' do
      get '/:id/?' do |id|
        member = Member[id.to_i]
        haml(:'member/show', locals: { member: member })
      end
    end
  end
end
