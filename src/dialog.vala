/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and creates the dialog
* menus like the Preference Dialog
*
* Bookworm is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Bookworm is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Bookworm. If not, see http://www.gnu.org/licenses/.
*/
using Gtk;
using Gee;
public class BookwormApp.AppDialog : Gtk.Dialog {
	public static Gtk.ComboBoxText profileCombobox;
	public static Gtk.ComboBoxText directoryComboBox;
	public static StringBuilder scanDirList = new StringBuilder("");
	public static BookwormApp.Settings settings;
	public static string[] profileColorList;

	public AppDialog () {
		settings = BookwormApp.Settings.get_instance();
		scanDirList.assign(BookwormApp.Bookworm.settings.list_of_scan_dirs);
	}

	public static Gtk.Popover createBookContextMenu (owned BookwormApp.Book aBook) {
        debug("[START] [FUNCTION:createBookContextMenu] aBook.location="+aBook.getBookLocation());
		Gtk.Popover bookContextPopover = new Gtk.Popover ((Gtk.EventBox) (aBook.getBookWidget("BOOK_EVENTBOX")));
		//Add the Menu title with the name of the book
		StringBuilder contextTitle = new StringBuilder();
		contextTitle.append(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_HEADER)
							.append(" ")
							.append(aBook.getBookTitle());
		//restrict the length of the label to 35 characters
		if(contextTitle.str.length > 35){
			contextTitle.assign(contextTitle.str.slice(0,35));
			contextTitle.append("...");
		}
		Label contextTitleLabel = new Label(contextTitle.str);
		//Add button for updating cover Image
		Gtk.Label updateCoverLabel = new Gtk.Label(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_COVER);
		Gtk.Image updateImageIcon = null;
		if (Gtk.IconTheme.get_default ().has_icon ("insert-image")) {
			updateImageIcon = new Gtk.Image.from_icon_name ("insert-image", Gtk.IconSize.MENU);
		}else{
			updateImageIcon = new Gtk.Image.from_file (BookwormApp.Constants.UPDATE_IMAGE_ICON_LOCATION);
		}
		Gtk.Button updateCoverImageButton = new Gtk.Button ();
		updateCoverImageButton.set_image (updateImageIcon);
		updateCoverImageButton.set_relief (ReliefStyle.NONE);
		updateCoverImageButton.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_UPDATING_COVER_IMAGE);
		Gtk.Box updateCoverImageBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		updateCoverImageBox.pack_start(updateCoverLabel,false, true, 0);
		updateCoverImageBox.pack_start(updateCoverImageButton,false, true, 0);
		//Add action for setting cover image
		updateCoverImageButton.clicked.connect (() => {
			ArrayList<string> selectedFiles = BookwormApp.Utils.selectFileChooser(Gtk.FileChooserAction.OPEN, _("Select Image"), 	
																																	  BookwormApp.Bookworm.window, false, "IMAGES");
			if(selectedFiles != null && selectedFiles.size > 0){
				string selectedCoverImagePath = selectedFiles.get(0);
				//copy cover image to bookworm cover image cache
	      		aBook = BookwormApp.Utils.setBookCoverImage(aBook, selectedCoverImagePath);
				aBook.setWasBookOpened(true);
				//Refresh the library view to show the new cover image
				try{
					Gdk.Pixbuf aBookCover = new Gdk.Pixbuf.from_file_at_scale(aBook.getBookCoverLocation(), 150, 200, false);
					Gtk.Image aCoverImage = new Gtk.Image.from_pixbuf(aBookCover);
					aCoverImage.set_halign(Align.START);
					aCoverImage.set_valign(Align.START);
					aBook.setBookWidget("COVER_IMAGE", aCoverImage);
					BookwormApp.Library.replaceCoverImageOnBook(aBook); //book is updated into library view map in this function call
					//remove the text from the title widget
					Gtk.Label titleTextLabel = (Gtk.Label) aBook.getBookWidget("TITLE_TEXT_LABEL");
					titleTextLabel.set_text("");
					aBook.setBookWidget("TITLE_TEXT_LABEL", titleTextLabel);
					//refresh the library view
					BookwormApp.AppWindow.library_grid.show_all();
					BookwormApp.Bookworm.toggleUIState();
					debug("Updated cover to image located at path:"+selectedCoverImagePath);
				}catch(GLib.Error e){
					warning("Error in getting the book cover image from location ["+aBook.getBookCoverLocation()+"] :" + e.message);
				}				
			}
		});

		//Add text entry for updating book title
		Gtk.Label updateTitleLabel = new Gtk.Label(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_TITLE);
		Gtk.Entry updateTitleEntry = new Gtk.Entry ();
		updateTitleEntry.set_text (BookwormApp.Utils.parseMarkUp(aBook.getBookTitle()));
		Gtk.Box updateTitleBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		updateTitleBox.pack_start(updateTitleLabel,false, true, 0);
		updateTitleBox.pack_end(updateTitleEntry,false, true, 0);
		//Add action for setting Book Title
		updateTitleEntry.focus_out_event.connect (() => {
			if(updateTitleEntry.get_text() != null && updateTitleEntry.get_text().length > 0){
				aBook.setBookTitle(updateTitleEntry.get_text());
				aBook.setWasBookOpened(true);
				if(!aBook.getIsBookCoverImagePresent()){
					//refresh the library view
					Gtk.Label titleTextLabel = (Gtk.Label) aBook.getBookWidget("TITLE_TEXT_LABEL");
					titleTextLabel.set_text("<b>"+aBook.getBookTitle()+"</b>");
					titleTextLabel.set_xalign(0.0f);
					titleTextLabel.set_use_markup (true);
					titleTextLabel.set_line_wrap (true);
		      		titleTextLabel.set_margin_start(BookwormApp.Constants.SPACING_WIDGETS);
		      		titleTextLabel.set_margin_end(BookwormApp.Constants.SPACING_WIDGETS);
		      		titleTextLabel.set_max_width_chars(-1);
					aBook.setBookWidget("TITLE_TEXT_LABEL", titleTextLabel);
					BookwormApp.AppWindow.library_grid.show_all();
					BookwormApp.Bookworm.toggleUIState();
				}
			}
			return false;
		});

		//Add text entry for updating book author
		Gtk.Label updateAuthorLabel = new Gtk.Label(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_AUTHOR);
		Gtk.Entry updateAuthorEntry = new Gtk.Entry ();
		updateAuthorEntry.set_text (aBook.getBookAuthor());
		Gtk.Box updateAuthorBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		updateAuthorBox.pack_start(updateAuthorLabel,false, true, 0);
		updateAuthorBox.pack_end(updateAuthorEntry,false, true, 0);
		//Add action for setting Book Title
		updateAuthorEntry.focus_out_event.connect (() => {
			if(updateAuthorEntry.get_text() != null && updateAuthorEntry.get_text().length > 0){
				aBook.setBookAuthor(updateAuthorEntry.get_text());
				aBook.setWasBookOpened(true);
			}
			return false;
		});

		//Add text entry for tags
		Gtk.Label updateTagsLabel = new Gtk.Label(BookwormApp.Constants.TEXT_FOR_BOOK_CONTEXTMENU_UPDATE_TAGS);
		Gtk.Entry updateTagsEntry = new Gtk.Entry ();
		updateTagsEntry.set_text (aBook.getBookTags());
		Gtk.Box updateTagsBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		updateTagsBox.pack_start(updateTagsLabel,false, true, 0);
		updateTagsBox.pack_end(updateTagsEntry,false, true, 0);
		//Add action for setting book tags
		updateTagsEntry.focus_out_event.connect (() => {
			if(updateTagsEntry.get_text() != null && updateTagsEntry.get_text().length > 0){
				aBook.setBookTags(updateTagsEntry.get_text());
				aBook.setWasBookOpened(true);
			}
			return false;
		});

		//Add/Update book ratings
		ArrayList<Gtk.Button> bookRatingList = new ArrayList<Gtk.Button> ();
		Gtk.Box ratingBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		ratingBox.set_halign(Align.CENTER);
		//set up the widgets for the rating
		for(int i=0; i<5; i++){
			Gtk.Image rating_star_image = null;
			if (Gtk.IconTheme.get_default ().has_icon ("non-starred")) {
				rating_star_image = new Gtk.Image.from_icon_name ("non-starred", Gtk.IconSize.MENU);
			}else{
				rating_star_image = new Gtk.Image.from_file (BookwormApp.Constants.RATING_NONE_IMAGE_ICON_LOCATION);
			}
			Gtk.Button rating_star_button = new Gtk.Button ();
			rating_star_button.set_image (rating_star_image);
			rating_star_button.set_relief (ReliefStyle.NONE);
			bookRatingList.add(rating_star_button);
			ratingBox.pack_start(rating_star_button,false, true, 0);
			//Add action for rating button
			rating_star_button.clicked.connect (() => {
				//set rating star clicked to active rating image
				if (Gtk.IconTheme.get_default ().has_icon ("starred")) {
					rating_star_button.set_image(new Gtk.Image.from_icon_name ("starred", Gtk.IconSize.MENU));
				}else{
					rating_star_button.set_image(new Gtk.Image.from_file (BookwormApp.Constants.RATING_SELECTED_IMAGE_ICON_LOCATION));
				}
				int ratingClicked = bookRatingList.index_of(rating_star_button);
				aBook.setBookRating(ratingClicked+1);
				aBook.setWasBookOpened(true);
				debug("Book Rating Set to:"+(ratingClicked+1).to_string());
				//Adjust rating display: set all stars with lower rating to active rating image
				for(int j=0; j<ratingClicked; j++){
					if (Gtk.IconTheme.get_default ().has_icon ("starred")) {
						((Gtk.Button)bookRatingList.get(j)).set_image(new Gtk.Image.from_icon_name ("starred", Gtk.IconSize.MENU));
					}else{
						((Gtk.Button)bookRatingList.get(j))
								.set_image(new Gtk.Image.from_file 	
												  (BookwormApp.Constants.RATING_SELECTED_IMAGE_ICON_LOCATION)
												  );
					}
				}
				//Adjust rating display: set all stars with higher rating to in-active rating image
				for(int k=ratingClicked+1; k<5; k++){
					if (Gtk.IconTheme.get_default ().has_icon ("non-starred")) {
						((Gtk.Button)bookRatingList.get(k)).set_image(new Gtk.Image.from_icon_name ("non-starred", Gtk.IconSize.MENU));
					}else{
						((Gtk.Button)bookRatingList.get(k))
								.set_image(new Gtk.Image.from_file 
												  (BookwormApp.Constants.RATING_NONE_IMAGE_ICON_LOCATION)
												  );
					}
				}
			});
		}
		//If any rating was given then represent the set_name
		if(aBook.getBookRating() > 0){
			for(int l=0; l<(aBook.getBookRating()); l++){
				if (Gtk.IconTheme.get_default ().has_icon ("starred")) {
					((Gtk.Button)bookRatingList.get(l)).set_image(new Gtk.Image.from_icon_name ("starred", Gtk.IconSize.MENU));
				}else{
					((Gtk.Button)bookRatingList.get(l))
							.set_image(new Gtk.Image.from_file 
											  (BookwormApp.Constants.RATING_SELECTED_IMAGE_ICON_LOCATION)
											  );
				}
			}
		}

		//Add all context widget items to a Context Box
		Gtk.Box bookContextMenuBox = new Gtk.Box(Orientation.VERTICAL, BookwormApp.Constants.SPACING_BUTTONS);
    	bookContextMenuBox.set_border_width(BookwormApp.Constants.SPACING_WIDGETS);
    	bookContextMenuBox.pack_start(contextTitleLabel, false, false);
    	bookContextMenuBox.pack_start(new Gtk.Separator (Gtk.Orientation.HORIZONTAL) , true, true, 0);
		bookContextMenuBox.pack_start(updateCoverImageBox, false, false);
		bookContextMenuBox.pack_start(updateTitleBox, false, false);
		bookContextMenuBox.pack_start(updateAuthorBox, false, false);
		bookContextMenuBox.pack_start(updateTagsBox, false, false);
		bookContextMenuBox.pack_start(new Gtk.Separator (Gtk.Orientation.HORIZONTAL) , true, true, 0);
		bookContextMenuBox.pack_end(ratingBox, false, false);
		//Set Context Box to Popover
		bookContextPopover.add(bookContextMenuBox);

		//update book when popover is closed
		bookContextPopover.closed.connect(() => {
			BookwormApp.Bookworm.libraryViewMap.set(aBook.getBookLocation(), aBook);
			debug("Popover closed and Book details updated...");
		});
        debug("[END] [FUNCTION:createBookContextMenu] aBook.location="+aBook.getBookLocation());
		return bookContextPopover;
	}

	public static void createPreferencesDialog () {
		debug("[START] [FUNCTION:createPreferencesDialog]");
		AppDialog dialog = new AppDialog ();
		dialog.set_transient_for(BookwormApp.Bookworm.window);
		profileColorList = settings.list_of_profile_colors.split (",");

    	dialog.title = BookwormApp.Constants.TEXT_FOR_PREFERENCES_DIALOG_TITLE;
		dialog.border_width = 5;
		dialog.set_default_size (600, 200);

		Gtk.Label localStorageLabel = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_LOCAL_STORAGE);
    	Gtk.Switch localStorageSwitch = new Gtk.Switch ();
    	//Set the switch to on if caching is set by saved settings
    	if(BookwormApp.Bookworm.settings.is_local_storage_enabled){
      		localStorageSwitch.set_active (true);
		}
		Gtk.Box localStorageBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		localStorageBox.pack_start(localStorageLabel, false, false);
		localStorageBox.pack_end(localStorageSwitch, false, false);

    	Gtk.Label colourScheme = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_COLOUR_SCHEME);
    	Gtk.Switch nightModeSwitch = new Gtk.Switch ();
    	//Set the switch to on if the Night Mode is set by saved settings
    	if(BookwormApp.Bookworm.settings.is_dark_theme_enabled){
      		nightModeSwitch.set_active (true);
		}
		Gtk.Box prefBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		prefBox.pack_start(colourScheme, false, false);
		prefBox.pack_end(nightModeSwitch, false, false);

		Gtk.Label twoPageViewLabel = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_TWO_PAGE);
    	Gtk.Switch twoPageViewSwitch = new Gtk.Switch ();
    	//Set the switch to on if two-page-view is set by saved settings
    	if(BookwormApp.Bookworm.settings.is_two_page_enabled){
      		twoPageViewSwitch.set_active (true);
		}
		Gtk.Box twoPageViewBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		twoPageViewBox.pack_start(twoPageViewLabel, false, false);
		twoPageViewBox.pack_end(twoPageViewSwitch, false, false);

		Gtk.Label showLibraryAtStartLabel = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_SKIP_LIBRARY);
    	Gtk.Switch showLibraryAtStartSwitch = new Gtk.Switch ();
    	//Set the switch to skip the library view and go straight to the last book being read
    	if(BookwormApp.Bookworm.settings.is_show_library_on_start){
      		showLibraryAtStartSwitch.set_active (true);
		}
		Gtk.Box showLibraryAtStartBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		showLibraryAtStartBox.pack_start(showLibraryAtStartLabel, false, false);
		showLibraryAtStartBox.pack_end(showLibraryAtStartSwitch, false, false);

		Gtk.Label fontChooserLabel = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_FONT);
		Gtk.FontButton fontButton = new Gtk.FontButton ();
		fontButton.set_filter_func (filterFont);
		fontButton.set_font_name(BookwormApp.Bookworm.settings.reading_font_name);
		fontButton.set_show_style (false);
		Gtk.Box fontBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		fontBox.pack_start(fontChooserLabel, false, false);
		fontBox.pack_end(fontButton, false, false);

		profileCombobox = new Gtk.ComboBoxText ();
		StringBuilder profileNameText = new StringBuilder();
		profileNameText.assign(BookwormApp.Constants.TEXT_FOR_PROFILE_CUSTOMIZATION).append(" 1");
		profileCombobox.append_text (profileNameText.str);
		profileNameText.assign(BookwormApp.Constants.TEXT_FOR_PROFILE_CUSTOMIZATION).append(" 2");
		profileCombobox.append_text (profileNameText.str);
		profileNameText.assign(BookwormApp.Constants.TEXT_FOR_PROFILE_CUSTOMIZATION).append(" 3");
		profileCombobox.append_text (profileNameText.str);

		Gtk.Label backgroundColourLabel = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PROFILE_CUSTOMIZATION_BACKGROUND_COLOR);
		Gtk.ColorButton backgroundColourButton = new Gtk.ColorButton ();
		backgroundColourButton.set_relief (ReliefStyle.HALF);
		Gtk.Box backgroundColourBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
		backgroundColourBox.pack_start(backgroundColourLabel, false, false);
		backgroundColourBox.pack_start(backgroundColourButton, false, false);

		Gtk.Label textColourLabel = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PROFILE_CUSTOMIZATION_FONT_COLOR);
		Gtk.ColorButton textColourButton = new Gtk.ColorButton ();
		textColourButton.set_relief (ReliefStyle.HALF);
		Gtk.Box textColourBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
		textColourBox.pack_start(textColourLabel, false, false);
		textColourBox.pack_start(textColourButton, false, false);

		Gtk.LinkButton preferencesReset = new Gtk.LinkButton.with_label ("reset", BookwormApp.Constants.TEXT_FOR_PREFERENCES_VALUES_RESET);
		Gtk.Box resetBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		resetBox.pack_end(preferencesReset, false, false);

		//set the value for the first profile
		profileCombobox.active = 0;
		var aRGBATextColor = Gdk.RGBA();
		aRGBATextColor.parse(profileColorList[0]);
		textColourButton.rgba = aRGBATextColor;

		var aRGBABackgroundColor = Gdk.RGBA();
		aRGBABackgroundColor.parse(profileColorList[1]);
		backgroundColourButton.rgba = aRGBABackgroundColor;

		Gtk.Label discoverBooksLabel = new Gtk.Label (BookwormApp.Constants.TEXT_FOR_PREFERENCES_BOOKS_DISCOVERY);
		directoryComboBox = new Gtk.ComboBoxText ();
		if(BookwormApp.Bookworm.settings.list_of_scan_dirs.length > 1){
			string[] scanDirList = settings.list_of_scan_dirs.split ("~~");
			foreach(string dir in scanDirList){
				if(dir != null && dir.length > 1) {
				 directoryComboBox.append_text (dir);
			 	}
			}
		}
		directoryComboBox.set_active(0);

		//Set up Button for adding scan directory
    	Gtk.Button add_scan_directory_button = new Gtk.Button ();
    	add_scan_directory_button.set_image (BookwormApp.Bookworm.add_scan_directory_image);
    	add_scan_directory_button.set_relief (ReliefStyle.NONE);
    	add_scan_directory_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_ADD_DIRECTORY);

    	//Set up Button for removing scan directory
    	Gtk.Button remove_scan_directory_button = new Gtk.Button ();
    	remove_scan_directory_button.set_image (BookwormApp.Bookworm.remove_scan_directory_image);
    	remove_scan_directory_button.set_relief (ReliefStyle.NONE);
    	remove_scan_directory_button.set_tooltip_markup (BookwormApp.Constants.TOOLTIP_TEXT_FOR_REMOVE_DIRECTORY);


		Gtk.Box discoverBooksBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 1);
		discoverBooksBox.pack_start(discoverBooksLabel, false, false);
		discoverBooksBox.pack_start(add_scan_directory_button, false, false);
		discoverBooksBox.pack_start(remove_scan_directory_button, false, false);
		discoverBooksBox.pack_end(directoryComboBox, false, false);

		Gtk.Box customProfileBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		customProfileBox.pack_start(profileCombobox, false, false);
		customProfileBox.pack_end(textColourBox, false, false);
		customProfileBox.pack_end(backgroundColourBox, false, false);

		var dialog_toast = new Granite.Widgets.Toast(BookwormApp.Constants.TEXT_BOOK_DISCOVERY_TOAST);

    	Gtk.Box content = dialog.get_content_area() as Gtk.Box;
		content.spacing = BookwormApp.Constants.SPACING_WIDGETS;
		content.pack_start (prefBox, false, false, 0);
		content.pack_start (localStorageBox, false, false, 0);
		content.pack_start (showLibraryAtStartBox, false, false, 0);
		content.pack_start (twoPageViewBox, false, false, 0);
		content.pack_start (fontBox, false, false, 0);
		content.pack_start (customProfileBox, false, false, 0);
		content.pack_start (discoverBooksBox, false, false, 0);
		content.pack_end (resetBox, true, true, 5);
		content.pack_end (dialog_toast, true, true, 0); //this should be the last item vertically
		
		dialog.show_all ();

    	//Set up Actions
		fontButton.font_set.connect (() => {
			// Emitted when a font has been chosen:
			string selectedFontandSize = fontButton.get_font_name ();
			string selectedFontFamily = fontButton.get_font_family().get_name();
			int selectedFontSize = 12;
			if(selectedFontandSize.index_of(" ") != -1){
				selectedFontSize = int.parse(selectedFontandSize.slice(selectedFontandSize.last_index_of(" "), selectedFontandSize.length));
			}
			BookwormApp.Bookworm.settings.reading_font_name = selectedFontandSize;
			BookwormApp.Bookworm.settings.reading_font_name_family = selectedFontFamily;
			BookwormApp.Bookworm.settings.reading_font_size = selectedFontSize;
			//Refresh the page if it is open
			BookwormApp.contentHandler.refreshCurrentPage();
		});

		localStorageSwitch.notify["active"].connect (() => {
			if (localStorageSwitch.active) {
        		BookwormApp.Bookworm.settings.is_local_storage_enabled = true;
			}else{
        		BookwormApp.Bookworm.settings.is_local_storage_enabled = false;
			}
		});

		showLibraryAtStartSwitch.notify["active"].connect (() => {
			if (showLibraryAtStartSwitch.active) {
        		BookwormApp.Bookworm.settings.is_show_library_on_start = true;
			}else{
        		BookwormApp.Bookworm.settings.is_show_library_on_start = false;
			}
		});

		twoPageViewSwitch.notify["active"].connect (() => {
			if (twoPageViewSwitch.active) {
        		BookwormApp.Bookworm.settings.is_two_page_enabled = true;
			}else{
        		BookwormApp.Bookworm.settings.is_two_page_enabled = false;
			}
			//Refresh the page if it is open
			BookwormApp.contentHandler.refreshCurrentPage();
		});

    	nightModeSwitch.notify["active"].connect (() => {
			if (nightModeSwitch.active) {
				//Set the dark theme
				BookwormApp.Bookworm.settings.is_dark_theme_enabled = true;
				Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
				//Set the default dark theme for webkit
				BookwormApp.Bookworm.settings.reading_profile = BookwormApp.Constants.BOOKWORM_READING_MODE[4];
				//Refresh the page if it is open
				BookwormApp.contentHandler.refreshCurrentPage();
			}else{
				//Set the light theme
				BookwormApp.Bookworm.settings.is_dark_theme_enabled = false;
				Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
				//Set the default light theme for webkit
				BookwormApp.Bookworm.settings.reading_profile = BookwormApp.Constants.BOOKWORM_READING_MODE[3];
				//Refresh the page if it is open
				BookwormApp.contentHandler.refreshCurrentPage();
			}
		});
		//Set text entry for text/background color based on selected profile
		profileCombobox.changed.connect (() => {
			if(profileCombobox.get_active_text().contains(" 1")){
				aRGBATextColor.parse(profileColorList[0]);
				textColourButton.rgba = aRGBATextColor;

				aRGBABackgroundColor.parse(profileColorList[1]);
				backgroundColourButton.rgba = aRGBABackgroundColor;
			}
			if(profileCombobox.get_active_text().contains(" 2")){
				aRGBATextColor.parse(profileColorList[2]);
				textColourButton.rgba = aRGBATextColor;

				aRGBABackgroundColor.parse(profileColorList[3]);
				backgroundColourButton.rgba = aRGBABackgroundColor;
			}
			if(profileCombobox.get_active_text().contains(" 3")){
				aRGBATextColor.parse(profileColorList[4]);
				textColourButton.rgba = aRGBATextColor;

				aRGBABackgroundColor.parse(profileColorList[5]);
				backgroundColourButton.rgba = aRGBABackgroundColor;
			}
		});

		textColourButton.color_set.connect (() => {
			if(profileCombobox.get_active_text().contains(" 1")){
				profileColorList[0] = rgba_to_hex(textColourButton.rgba,false, true);
			}
			if(profileCombobox.get_active_text().contains(" 2")){
				profileColorList[2] = rgba_to_hex(textColourButton.rgba,false, true);
			}
			if(profileCombobox.get_active_text().contains(" 3")){
				profileColorList[4] = rgba_to_hex(textColourButton.rgba,false, true);
			}
			updateProfileColorToSettings();
			//Refresh the page if it is open
			BookwormApp.contentHandler.refreshCurrentPage();
		});

		backgroundColourButton.color_set.connect (() => {
			if(profileCombobox.get_active_text().contains(" 1")){
				profileColorList[1] = rgba_to_hex(backgroundColourButton.rgba,false, true);
			}
			if(profileCombobox.get_active_text().contains(" 2")){
				profileColorList[3] = rgba_to_hex(backgroundColourButton.rgba,false, true);
			}
			if(profileCombobox.get_active_text().contains(" 3")){
				profileColorList[5] = rgba_to_hex(backgroundColourButton.rgba,false, true);
			}
			updateProfileColorToSettings();
			//Refresh the page if it is open
			BookwormApp.contentHandler.refreshCurrentPage();
		});

		//Add selected watched folder
		add_scan_directory_button.clicked.connect ( () => {
			ArrayList<string> selectedDir = BookwormApp.Utils.selectDirChooser(_("Select folder"), BookwormApp.Bookworm.window, false);
			TreeModel aTreeModel = directoryComboBox.get_model();
			TreeIter iter;
			aTreeModel.get_iter_first (out iter);
			int numberOfDirs = aTreeModel.iter_n_children (iter);
			foreach (string dir in selectedDir) {
				directoryComboBox.append_text (dir);
				scanDirList.append(dir).append("~~");
				BookwormApp.Bookworm.settings.list_of_scan_dirs = scanDirList.str;
				numberOfDirs++;
				directoryComboBox.set_active(numberOfDirs);
				debug("value of scanDirList after adding dir:"+scanDirList.str);
			}
			//show a toast to indicate discovery will be done when Bookworm is closed
			dialog_toast.send_notification ();
		});
		//Remove selected watched folder
		remove_scan_directory_button.clicked.connect (() => {
			if(directoryComboBox  !=  null && 
				directoryComboBox.get_active_text()  !=  null  && 
				directoryComboBox.get_active_text().length > 1)
			{
				scanDirList.assign(scanDirList.str.replace(directoryComboBox.get_active_text ()+"~~", ""));
				debug("value of scanDirList after removal of ["+directoryComboBox.get_active_text ()+"]:"+scanDirList.str);
				BookwormApp.Bookworm.settings.list_of_scan_dirs = scanDirList.str;
				int currentActiveID = directoryComboBox.get_active();
				directoryComboBox.remove(currentActiveID);
			}
		});
		preferencesReset.activate_link.connect (() => {
			//Reset Profile Colors
			GLib.Settings bookwormSettings = new GLib.Settings (BookwormApp.Constants.bookworm_id);
			string defaultProfileColors = (string) bookwormSettings.get_default_value ("list-of-profile-colors");
			profileColorList = defaultProfileColors.split (",");
			//set the text based on the selected profile
			if(profileCombobox.get_active_text().contains(" 1")){
				aRGBATextColor.parse(profileColorList[0]);
				textColourButton.rgba = aRGBATextColor;
				aRGBABackgroundColor.parse(profileColorList[1]);
				backgroundColourButton.rgba = aRGBABackgroundColor;
			}
			if(profileCombobox.get_active_text().contains(" 2")){
				aRGBATextColor.parse(profileColorList[2]);
				textColourButton.rgba = aRGBATextColor;
				aRGBABackgroundColor.parse(profileColorList[3]);
				backgroundColourButton.rgba = aRGBABackgroundColor;
			}
			if(profileCombobox.get_active_text().contains(" 3")){
				aRGBATextColor.parse(profileColorList[4]);
				textColourButton.rgba = aRGBATextColor;
				aRGBABackgroundColor.parse(profileColorList[5]);
				backgroundColourButton.rgba = aRGBABackgroundColor;
			}
			//reset the settings value for profile colors
			settings.list_of_profile_colors = defaultProfileColors;

			//Reset Two-Page-View
			twoPageViewSwitch.set_active (false);
			BookwormApp.Bookworm.settings.is_two_page_enabled = (bool) bookwormSettings.get_default_value ("is-two-page-enabled");

			//Reset Caching
			localStorageSwitch.set_active (true);
			BookwormApp.Bookworm.settings.is_local_storage_enabled = (bool) bookwormSettings.get_default_value ("is-local-storage-enabled");

			//Reset Library at start option
			showLibraryAtStartSwitch.set_active (false);
			BookwormApp.Bookworm.settings.is_show_library_on_start = (bool) bookwormSettings.get_default_value ("is-show-library-on-start");;

			//Reset Dark Theme
			nightModeSwitch.set_active (false);
			BookwormApp.Bookworm.settings.is_dark_theme_enabled = (bool) bookwormSettings.get_default_value ("is-dark-theme-enabled");

			//Reset Font
			BookwormApp.Bookworm.settings.reading_font_name = (string) bookwormSettings.get_default_value ("reading-font-name");
			BookwormApp.Bookworm.settings.reading_font_name_family = (string) bookwormSettings.get_default_value ("reading-font-name-family");
			BookwormApp.Bookworm.settings.reading_font_size = (int) bookwormSettings.get_default_value ("reading-font-size");
			fontButton.set_font_name(BookwormApp.Bookworm.settings.reading_font_name);

			//Refresh the page if it is open
			BookwormApp.contentHandler.refreshCurrentPage();

			return true;
		});

		dialog.response.connect (() => {
			updateProfileColorToSettings();
		});
		debug("[END] [FUNCTION:createPreferencesDialog]");
	}

	public static void updateProfileColorToSettings(){
		debug("[START] [FUNCTION:updateProfileColorToSettings]");
		//build the profile color list to update the settings
		StringBuilder listOfProfileColors = new StringBuilder();
		foreach(string aProfileColor in profileColorList){
			listOfProfileColors.append(aProfileColor).append(",");
		}
		settings.list_of_profile_colors = listOfProfileColors.str.slice(0, (listOfProfileColors.str.length-1));
		//reload the css provider to reflect the updated css
		BookwormApp.Bookworm.loadCSSProvider(BookwormApp.Bookworm.cssProvider);
		debug("[END] [FUNCTION:updateProfileColorToSettings]");
	}

	public static bool filterFont (Pango.FontFamily family, Pango.FontFace face) {
		if (face.get_face_name () != "Regular"){
			return false;
		}
		return true;
	}

	public static string rgba_to_hex (Gdk.RGBA color, bool alpha = false, bool prefix_hash = true){
		/* Converts the color in RGBA to hex */
		string hex = "";
		if (alpha){
			hex = "%02x%02x%02x%02x".printf((uint)(Math.round(color.red*255)),
																	 (uint)(Math.round(color.green*255)),
																	 (uint)(Math.round(color.blue*255)),
																	 (uint)(Math.round(color.alpha*255))).up();
		}else{
			hex = "%02x%02x%02x".printf((uint)(Math.round(color.red*255)),(uint)(Math.round(color.green*255)),(uint)(Math.round(color.blue*255))).up();
		}
		if (prefix_hash){
			hex = "#" + hex;
		}
		return hex;
	}

	public static void createAnnotationDialog (string textForAnnotation) {
		debug("[START] [FUNCTION:createAnnotationDialog] textForAnnotation="+textForAnnotation);
		Gtk.Dialog annotationDialog = new Gtk.Dialog();
		annotationDialog.set_transient_for(BookwormApp.Bookworm.window);
		annotationDialog.border_width = 0;
		annotationDialog.set_default_size (600, 400);
		BookwormApp.Book aBook = BookwormApp.Bookworm.libraryViewMap.get(BookwormApp.Bookworm.locationOfEBookCurrentlyRead);

		Gtk.Label annotationsLabel = new Label(BookwormApp.Constants.TEXT_FOR_ANNOTATION + 
																			BookwormApp.Utils.minimizeStringLength(textForAnnotation, 35));
		annotationsLabel.set_line_wrap (true);
    	Gtk.TextView annotationsInputTextView = new Gtk.TextView();
    	annotationsInputTextView.set_wrap_mode (Gtk.WrapMode.WORD);
    	annotationsInputTextView.buffer.text = aBook.getAnnotations(aBook.getBookPageNumber().to_string()+"#~~#"+textForAnnotation);
		Gtk.ScrolledWindow scrolledAnnotations = new Gtk.ScrolledWindow (null, null);
		scrolledAnnotations.add (annotationsInputTextView);

		Gtk.Label annotationsTagLabel = new Label(BookwormApp.Constants.TEXT_FOR_ANNOTATION_TAG);
		Gtk.Entry annotationTagEntry = new Gtk.Entry ();
		annotationTagEntry.set_tooltip_markup (BookwormApp.Constants.TEXT_FOR_ANNOTATION_TAG_ENTRY);
		annotationTagEntry.set_text(aBook.getAnnotationTags());
		Gtk.Box annotationTagBox = new Gtk.Box (Orientation.HORIZONTAL, BookwormApp.Constants.SPACING_WIDGETS);
		annotationTagBox.pack_start(annotationsTagLabel, false, false, 0);
		annotationTagBox.pack_start(annotationTagEntry, false, true, 0);

		Gtk.Box content = annotationDialog.get_content_area() as Gtk.Box;
		content.spacing = BookwormApp.Constants.SPACING_WIDGETS;
		content.pack_start (annotationsLabel, false, false, 0);
		content.pack_start (scrolledAnnotations, true, true, 0);
		content.pack_start (annotationTagBox, false, true, 0);
		annotationDialog.show_all();

		annotationDialog.destroy.connect (() => {
			aBook.setAnnotations(aBook.getBookPageNumber().to_string()+"#~~#"+textForAnnotation,annotationsInputTextView.buffer.text);
			aBook.setAnnotationTags(annotationTagEntry.get_text());
			BookwormApp.Utils.setWebViewTitle("document.title = ' '");
			aBook = BookwormApp.contentHandler.renderPage(aBook, "");
		});
		debug("[END] [FUNCTION:createAnnotationDialog] textForAnnotation="+textForAnnotation);
	}
}
