defmodule MoodleNet.AccountsTest do
  use MoodleNet.DataCase, async: true

  alias MoodleNet.Accounts
  alias MoodleNet.Accounts.{User, PasswordAuth}

  describe "register_user" do
    test "works" do
      icon_attrs = Factory.attributes(:image)
      attrs = Factory.attributes(:user)
              |> Map.put("icon", icon_attrs)
              |> Map.put("extra_field", "extra")
      assert {:ok, ret} = Accounts.register_user(attrs)
      assert attrs["email"] == ret.user.email
      assert attrs["preferred_username"] == ret.actor[:preferred_username]
      assert ret.actor
      assert ret.actor[:extra_field] == attrs["extra_field"]
      assert [icon] = ret.actor[:icon]
      assert icon[:url] == icon_attrs["url"]
    end

    test "fails with invalid password values" do
      attrs = @register_attrs |> Map.delete(:password)
      assert {:error, _, ch, _} = Accounts.register_user(attrs)
      assert "can't be blank" in errors_on(ch).password

      attrs = @register_attrs |> Map.put(:password, "short")
      assert {:error, _, ch, _} = Accounts.register_user(attrs)
      assert "should be at least 6 character(s)" in errors_on(ch).password
    end

    test "fails with invalid email" do
      attrs = @register_attrs |> Map.delete(:email)
      assert {:error, _, ch, _} = Accounts.register_user(attrs)
      assert "can't be blank" in errors_on(ch).email

      attrs = @register_attrs |> Map.put(:email, "not_an_email")
      assert {:error, _, ch, _} = Accounts.register_user(attrs)
      assert "has invalid format" in errors_on(ch).email
    end

    test "lower case the email" do
      attrs = Map.put(@register_attrs , :email, String.upcase(@register_attrs.email))
      assert {:ok, ret} = Accounts.register_user(attrs)
      assert ret.user.email == @register_attrs.email
    end
  end

  describe "authenticate_by_email_and_pass" do
    test "works" do
      assert {:ok, ret} = Accounts.register_user(@register_attrs)
      assert %{user: %{id: user_id}} = ret
      assert {:ok, %User{id: ^user_id}} =
        Accounts.authenticate_by_email_and_pass(@register_attrs.email, @register_attrs.password)

      assert {:error, :unauthorized} =
        Accounts.authenticate_by_email_and_pass(@register_attrs.email, "other_thing")

      assert {:error, :not_found} =
        Accounts.authenticate_by_email_and_pass("other@email.es", @register_attrs.password)
    end

    test "unauthorized with invalid input" do
      assert {:ok, _} = Accounts.register_user(@register_attrs)
    end
  end
end