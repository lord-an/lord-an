module Store
  class ImageAttachmentsValidator < ActiveModel::EachValidator
    CONTENT_TYPES = %w[ image/jpeg image/png image/webp ].freeze
    DEFAULT_MAX_SIZE = 5.megabytes

    def validate_each(record, attribute, attachment)
      return unless attachment.attached?

      attachments = attachment.respond_to?(:attachments) ? attachment.attachments : [ attachment.attachment ]
      max_count = options.fetch(:max_count, 1)
      max_size = options.fetch(:max_size, DEFAULT_MAX_SIZE)

      if attachments.size > max_count
        record.errors.add(attribute, "cannot include more than #{max_count} files")
        return
      end

      attachments.each do |attached_file|
        blob = attached_file.blob
        if blob.byte_size > max_size
          record.errors.add(attribute, "must be smaller than #{max_size / 1.megabyte} MB")
          next
        end

        actual_content_type, actual_size = inspect_file(record, attribute, attached_file)
        if actual_size > max_size
          record.errors.add(attribute, "must be smaller than #{max_size / 1.megabyte} MB")
          next
        end

        unless CONTENT_TYPES.include?(blob.content_type) && CONTENT_TYPES.include?(actual_content_type)
          record.errors.add(attribute, "must be an image")
        end
      end
    end

    private
      def inspect_file(record, attribute, attached_file)
        blob = attached_file.blob
        change = record.attachment_changes[attribute.to_s]
        attachable = find_attachable(change, blob)

        inspection = with_upload_io(attachable) { |io| [ Marcel::MimeType.for(io), io.size ] } if attachable
        inspection || blob.open { |file| [ Marcel::MimeType.for(file), file.size ] }
      end

      def find_attachable(change, blob)
        if change.respond_to?(:attachable)
          change.attachable if change.blob == blob
        elsif change.respond_to?(:attachables)
          index = change.blobs.index { |attached_blob| attached_blob.key == blob.key }
          change.attachables[index] if index
        end
      end

      def with_upload_io(attachable)
        close_io = false
        io = case attachable
        when Hash
          attachable.fetch(:io)
        when File
          attachable
        when Pathname
          close_io = true
          attachable.open
        else
          if attachable.respond_to?(:open)
            close_io = true
            attachable.open
          end
        end

        return if io.nil?

        original_position = io.pos if io.respond_to?(:pos)
        yield io
      ensure
        if io
          close_io ? io.close : io.seek(original_position) if original_position && io.respond_to?(:seek)
          io.close if close_io && !io.closed?
        end
      end
  end
end
