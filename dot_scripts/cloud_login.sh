# Workforce-pool (Okta) is a third-party login flow: `--update-adc` is rejected
# there, so ADC must be refreshed with a separate application-default login.
gcloud auth login
gcloud auth application-default login