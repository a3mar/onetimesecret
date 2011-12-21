
require 'onetime/app/api/base'

class Onetime::App
  class API
    include Onetime::App::API::Base
    
    def status
      authorized do
        sess.event_incr! :check_status
        json :status => :nominal
      end
    end
    
    def share
      authorized do
        req.params[:kind] = :share
        logic = OT::Logic::CreateSecret.new sess, cust, req.params
        logic.raise_concerns
        logic.process
        if req.get?
          res.redirect app_path(logic.redirect_uri)
        else
          json metadata_hsh(logic.metadata)
        end
      end
    end
    
    def generate
      authorized do
        req.params[:kind] = :generate
        logic = OT::Logic::CreateSecret.new sess, cust, req.params
        logic.raise_concerns
        logic.process
        if req.get?
          res.redirect app_path(logic.redirect_uri)
        else
          json metadata_hsh(logic.metadata, :value => logic.secret_value)
        end
      end
    end
    
    def show_secret
      authorized do
        req.params[:continue] = 'true'
        logic = OT::Logic::ShowSecret.new sess, cust, req.params
        logic.raise_concerns
        logic.process
        if logic.show_secret
          json :value => logic.secret_value, :secret_key => req.params[:key]
          logic.secret.viewed!
        else
          secret_not_found_response
        end
      end
    end
    
    def show_metadata
      authorized do
        logic = OT::Logic::ShowMetadata.new sess, cust, req.params
        logic.raise_concerns
        logic.process
        if logic.show_secret
          secret = md.load_secret
          secret_value = secret.can_decrypt? ? secret.decrypted_value : nil
          json metadata_hsh(logic.metadata, :value => secret_value)
          logic.metadata.delete :secret_key
        else
          json metadata_hsh(logic.metadata)
        end
      end
    end
    
    private
    def metadata_hsh md, opts={}
      hsh = md.all
      ret = {
        :custid => hsh['custid'],
        :metadata_key => hsh['key'],
        :secret_key => hsh['secret_key'],
        :ttl => hsh['ttl'].to_i,
        :state => hsh['state'] || 'new',
        :updated => hsh['updated'],
        :created => hsh['created']
      }
      ret[:shared] = hsh['shared'] if hsh['state'].to_s == 'shared'
      ret[:value] = opts[:value] if opts[:value]
      ret
    end
          
    
  end
end