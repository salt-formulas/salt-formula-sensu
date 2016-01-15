#!/usr/bin/env ruby
#
# check-smtp
#
# DESCRIPTION:
# Check SMTP connection to a server
#
# OUTPUT:
# plain text
#
# PLATFORMS:
# Linux
#
# DEPENDENCIES:
# gem: sensu-plugin
#
# USAGE:
# check-smtp -h HOST [-p PORT] [-H HELO ]
#
# NOTES:
#
# LICENSE:
# Oasiswork <dev@oasiswork.fr>
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# AUTHORS:
# Nicolas BRISAC <nbrisac@oasiswork.fr>

require 'sensu-plugin/check/cli'
require 'net/smtp'

class CheckSMTP < Sensu::Plugin::Check::CLI
    option :host,
            short: '-h HOST',
            description: 'SMTP host to connect to',
            required: true

    option :port,
            short: '-p PORT',
            description: 'SMTP port to connect to',
            default: 25

    option :tls,
            long: '--tls',
            description: 'Enable STARTTLS',
            boolean: true

    option :tls_verify,
            long: '--verify-peer-cert',
            description: 'Verify peer certificate during TLS session',
            boolean: true

    def run
        smtp = Net::SMTP.new(config[:host], config[:port])
        ctx = OpenSSL::SSL::SSLContext.new
        if config[:tls_verify]
            ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
            ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        begin
            if config[:tls]
                smtp.enable_starttls(ctx)
            end
            smtp.start(Socket.gethostname)
            smtp.finish()
        rescue Exception => e
            critical "Connection failed: #{e.message}"
        end        

        ok
    end
end
