defmodule Rageq.UserTest do
  use Rageq.ModelCase

  alias Rageq.User

  @valid_create_attrs %{
    email: "some content",
    name: "some content",
    username: "epicname",
    password: "123",
    password_confirmation: "123"
  }
  @valid_attrs %{
    email: "some content",
    name: "some content",
    username: "epicname"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_create_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "password_digest gets set to a hash" do
    changeset = User.changeset(%User{}, @valid_create_attrs)
    assert Comeonin.Bcrypt.checkpw(@valid_create_attrs.password, Ecto.Changeset.get_change(changeset, :password_digest))
  end

  test "password_digest doesn't get set if the password is nil" do
    changeset = User.changeset(%User{},%{email: "test@test.com", password: nil, password_confirmation: nil, username: "test"})
    refute Ecto.Changeset.get_change(changeset, :password_digest)
  end
end
