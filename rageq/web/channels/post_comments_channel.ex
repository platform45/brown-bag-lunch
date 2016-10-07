defmodule Rageq.PostCommentsChannel do
  use Rageq.Web, :channel
  alias Rageq.CommentHelper
  import IEx

  def join("post_comments:" <> _post_id, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("created_comment", payload, socket) do
    # {:reply, {:ok, payload}, socket}
    case CommentHelper.create(payload, socket) do
      {:ok, comment} ->
        comment = CommentHelper.get(comment.id)
        payload = Map.delete(payload, "user_id")
        broadcast socket, "created_comment", Map.merge(payload, %{inserted_at: comment.inserted_at, comment_id: comment.id, user: comment.user.username})
        {:noreply, socket}
      {:error, _} ->
        {:noreply, socket}
    end
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (post_comments:lobby).
  # def handle_in("shout", payload, socket) do
    # broadcast socket, "shout", payload
    # {:noreply, socket}
  # end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
