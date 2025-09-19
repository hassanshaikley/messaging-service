# Notes

- Used Phoenix + Generator as opposd to plug / from scratch for efficiency
- Add a LiveView interface for ease of use + testing but didn't get around to actually doing this. That's why I didn't exclude LV and html.
  - Even when building an API having a LiveView interface for internal use is very nice to have and often simplifies things like QA and debugging.
- Use env files for dev + testing (dotenv lib) just to make sharing between docker-compose and local easier.
  - Not the biggest fan of this pattern but it's better than without it IMHO.
  - Can also use .env.example and force the user to do some legwork to get the values, if there's anything sensitive then will have to do that.
- Save API requests and responses for debugging / being able to replay if a bug fixes
- Kind of like the Adapter pattern for this kind of thing https://aaronrenner.io/2023/07/22/elixir-adapter-pattern.html
  - Has some pitfalls you need to watch out for.

- Just use the same table for messages and put the attachments in an array of strings, don't see need for relational table as they aren't really updated but it does make adding additional features and doing some extra things a little easier.
- Would want to log a lot in this kind of app
- Assuming conversations can be unique - HOWEVER need to normalize the participant addresses to fully do this, unless we know phone numbers will be formatted the same
- Also might want to put creating the conversation + the message in a transaction, so we don't have conversations when message creation fails
- Some things are generated and extranous. Normally I would go through and remove what is not needed + refactor a bit more but I did not in the interest of time.
- 429 is rate limiting. So when producing I think there needs to be some kind of architecture in place to handle that. OR even if there are 500s. When rate limited you have to try again later. I like processing webhooks in jobs so that it doesn't overwhelm a system. You may need to do something like that as well when communicating with these providers.


## Places for improvement

- Assume phone is the same (in the tests at least) +1 followed by 10 digits
- Validation should be improved (IE SMS message length limits)
- Might be good to do something for idempotency
- Some nice to haves would be:
  - Credo
  - Compile warnings as errors checkl
  - Could have sworn I used UUIDs in the generator, welp, it's integers! Prefer UUIDs
  - Sobelow is always good
