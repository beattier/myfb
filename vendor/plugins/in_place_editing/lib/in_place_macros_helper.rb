module InPlaceMacrosHelper

  # Makes an HTML element specified by the DOM ID +field_id+ become an in-place
  # editor of a property.
  #
  # A form is automatically created and displayed when the user clicks the element,
  # something like this:
  #   <form id="myElement-in-place-edit-form" target="specified url">
  #     <input name="value" text="The content of myElement"/>
  #     <input type="submit" value="ok"/>
  #     <a onclick="javascript to cancel the editing">cancel</a>
  #   </form>
  #
  # The form is serialized and sent to the server using an AJAX call, the action on
  # the server should process the value and return the updated value in the body of
  # the reponse. The element will automatically be updated with the changed value
  # (as returned from the server).
  #
  # Required +options+ are:
  # <tt>:url</tt>::       Specifies the url where the updated value should
  #                       be sent after the user presses "ok".
  #
  # Addtional +options+ are:
  # <tt>:rows</tt>::                  Number of rows (more than 1 will use a TEXTAREA)
  # <tt>:cols</tt>::                  Number of characters the text input should span (works for both INPUT and TEXTAREA)
  # <tt>:size</tt>::                  Synonym for :cols when using a single line text input.
  # <tt>:highlight_color</tt>::       Hex color for the start of the highlight. (default: yellow)
  # <tt>:highlight_end_color</tt>::   Hex color for the end of the highlight. (default: white)
  # <tt>:cancel_text</tt>::           The text on the cancel link. (default: "cancel")
  # <tt>:save_text</tt>::             The text on the save link. (default: "ok")
  # <tt>:save_control_type</tt>::     The type of control for the save link. (default: "button")
  # <tt>:cancel_control_type</tt>::   The type of control for the cancel link. (default: "link")
  # <tt>:loading_text</tt>::          The text to display while the data is being loaded from the server (default: "Loading...")
  # <tt>:saving_text</tt>::           The text to display when submitting to the server (default: "Saving...")
  # <tt>:external_control</tt>::      The id of an external control used to enter edit mode.
  # <tt>:external_control_only</tt>:: Only allow the use of the external control to enter edit mode. (default: false)
  # <tt>:load_text_url</tt>::         URL where initial value of editor (content) is retrieved.
  # <tt>:options</tt>::               Pass through options to the AJAX call (see prototype's Ajax.Updater)
  # <tt>:with</tt>::                  JavaScript snippet that should return what is to be sent
  #                                   in the AJAX call, +form+ is an implicit parameter
  # <tt>:script</tt>::                Instructs the in-place editor to evaluate the remote JavaScript response (default: false)
  # <tt>:click_to_edit_text</tt>::    The text shown during mouseover the editable text (default: "Click to edit")
  # <tt>:failure</tt>::               Javascript callback on failure (500).
  # <tt>:complete</tt>::              Javascript callback fires when the request is complete.
  # <tt>:enter_editing</tt>::         Javascript callback fires when beginning to edit.
  # <tt>:exit_editing</tt>::          Javascript callback fires when ending the edit.
  def in_place_editor(field_id, options = {})
    function =  ""
    function << "document.observe('dom:loaded', function(e){" unless controller.request.xhr?
    function << "new Ajax.InPlaceEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    js_options = {}

    if protect_against_forgery?
      options[:with] ||= "Form.serialize(form)"
      options[:with] += " + '&authenticity_token=' + encodeURIComponent('#{form_authenticity_token}')"
    end

    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['okControl'] = %('#{options[:save_control_type]}') if options[:save_control_type]
    js_options['cancelControl'] = %('#{options[:cancel_control_type]}') if options[:cancel_control_type]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['externalControlOnly'] = "true" if options[:external_control_only]
    js_options['submitOnBlur'] = "'#{options[:submit_on_blur]}'" if options[:submit_on_blur]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]
    js_options['ajaxOptions'] = options[:options].send(options[:options].is_a?(String) ? :to_s : :to_json) if options[:options]
    js_options['htmlResponse'] = !options[:script] if options[:script]
    js_options['callback']   = "function(form, value) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['textBetweenControls'] = %('#{options[:text_between_controls]}') if options[:text_between_controls]
    js_options['highlightcolor'] = %('#{options[:highlight_color]}') if options[:highlight_color]
    js_options['highlightendcolor'] = %('#{options[:highlight_end_color]}') if options[:highlight_end_color]
    js_options['onFailure'] = "function(element, transport) { #{options[:failure]} }" if options[:failure]
    js_options['onComplete'] = "function(transport, element) { #{options[:complete]} }" if options[:complete]
    js_options['onEnterEditMode'] = "function(element) { #{options[:enter_editing]} }" if options[:enter_editing]
    js_options['onLeaveEditMode'] = "function(element) { #{options[:exit_editing]} }" if options[:exit_editing]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?

    function << ')'
    function << '})' unless controller.request.xhr?

    javascript_tag(function)
  end

  # Renders the value of the specified object and method with in-place editing capabilities.
  def in_place_editor_field(object, method, tag_options = {}, in_place_editor_options = {})
    instance_tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = {:tag => "span",
                   :id => "#{object}_#{method}_#{instance_tag.object.id}_in_place_editor",
                   :class => "in_place_editor_field"}.merge!(tag_options)
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :action => "set_#{object}_#{method}", :id => instance_tag.object.id })
    in_place_editor_options[:with] = in_place_editor_options[:with] || %{'#{object}[#{method}]='+encodeURIComponent(value)}
    pre_edit_text = h(instance_tag.value(instance_tag.object))
    if block_given?
      pre_edit_text = yield pre_edit_text
    end
    tag = content_tag(tag_options.delete(:tag), pre_edit_text, tag_options)
    return tag + in_place_editor(tag_options[:id], in_place_editor_options)
  end
  
   #CHANGE: The following two methods were added to allow in place editing with a select field instead of a text field.
  # For more info visit: http://www.thetacom.info/2008/03/21/rails-in-place-editing-plugin-w-selection/
  # Scriptaculous Usage: new Ajax.InPlaceCollectionEditor( element, url, { collection: [array], [moreOptions] } );
  def in_place_collection_editor(field_id, options = {})
    
    def text(key, options)
      options_value = options["#{key}_text".to_sym]
      locale_value = I18n.translate("in_place_editing.text.#{key}", :locale => options[:locale]) if !options_value
      value = options_value || (locale_value if !locale_value.start_with? "translation missing: ")
      "'#{value}'" if value
    end
    
    function = "new Ajax.InPlaceCollectionEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"
 
    #CHANGED: Added to allow plugin to work with Rails 2 session forgery protection
    if protect_against_forgery?
      options[:with] ||= "Form.serialize(form)"
      options[:with] += " + '&authenticity_token=' + encodeURIComponent('#{form_authenticity_token}')"
    end
    #end CHANGE
 
    js_options = {}
    js_options['collection'] = %(#{options[:collection]})
    js_options['cancelText'] = text(:cancel, options) if text(:cancel, options)
    js_options['okText'] = text(:save, options) if text(:save, options)
    js_options['loadingText'] = text(:loading, options) if text(:loading, options)
    js_options['savingText'] = text(:saving, options) if text(:saving, options)
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]
    js_options['ajaxOptions'] = options[:options] if options[:options]
    #CHANGED: To bring in line with current scriptaculous usage
    js_options['htmlResponse'] = !options[:script] if options[:script]
    js_options['callback'] = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = text(:click_to_edit, options) if text(:click_to_edit, options)
    js_options['textBetweenControls'] = %('#{options[:text_between_controls]}') if options[:text_between_controls]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?
 
    function << ')'
 
    javascript_tag(function)
  end
 
  # Renders the value of the specified object and method with in-place select capabilities.
  def in_place_editor_select_field(object, method, tag_options = {}, in_place_editor_options = {})
    instance_tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = {:tag => "span",
                   :id => "#{object}_#{method}_#{instance_tag.object.id}_in_place_editor",
                   :class => "in_place_editor_field"}.merge!(tag_options)
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :action => "set_#{object}_#{method}", :id => instance_tag.object.id })
    tag = content_tag(tag_options.delete(:tag), h(instance_tag.value(instance_tag.object)),tag_options)
    return tag + in_place_editor(tag_options[:id], in_place_editor_options)
  end

end
