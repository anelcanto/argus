defmodule Argus.Github.Graphql do
  @moduledoc false
  @review_threads_query """
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewDecision
        reviewThreads(first: 100) {
          nodes {
            isResolved
            comments(first: 1) {
              nodes {
                author {
                  login
                }
                body
              }
            }
          }
        }
      }
    }
  }
  """

  def review_threads_query, do: @review_threads_query
end
