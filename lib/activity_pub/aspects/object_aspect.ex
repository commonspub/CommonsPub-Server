defmodule ActivityPub.ObjectAspect do
  use ActivityPub.Aspect, persistence: ActivityPub.SQLObjectAspect

  alias ActivityPub.{LanguageValueType, StringListType}

  aspect do
    assoc(:attachment)
    assoc(:attributed_to)
    assoc(:attributed_to_inv, inv: :attributed_to)
    assoc(:audience)
    field(:content, LanguageValueType, default: %{})
    assoc(:context)
    assoc(:context_inv, inv: :context)
    field(:name, LanguageValueType, default: %{})
    field(:end_time, :utc_datetime)
    assoc(:generator)
    assoc(:icon)
    assoc(:image)
    # FIXME
    assoc(:in_reply_to)
    assoc(:location)
    assoc(:preview)
    field(:published, :utc_datetime)
    # FIXME
    assoc(:replies, inv: :in_reply_to)
    field(:start_time, :utc_datetime)
    field(:summary, LanguageValueType, default: %{})
    assoc(:tag)
    field(:updated, :utc_datetime)
    # FIXME url is a relation
    # field(:url, EntityType, default: [])
    field(:url, StringListType, default: [])
    field(:to, StringListType, default: [])
    field(:bto, StringListType, default: [])
    field(:cc, StringListType, default: [])
    field(:bcc, StringListType, default: [])
    field(:media_type, :string)
    field(:duration, :string)
  end
end
