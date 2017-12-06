# generate token for jwt authentication with Profiles service, valid for 12 months
ENV['VOLPINO_TOKEN'] = User.generate_token(exp: 3600 * 30 * 12)
