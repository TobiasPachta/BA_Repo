using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float move_speed = 10f;
    public Rigidbody2D rb;
    private Vector3 input_position;

    void Awake() {
        //get player object
        rb = GetComponent<Rigidbody2D>();
        //set player move speed relative to screen size
        move_speed = Camera.main.ScreenToWorldPoint(new Vector3(Screen.width, Screen.height,0)).x;
        input_position = transform.position;
    }

    // Update is called once per frame
    void Update() {
        //if user input is detected set new location
        if (Input.GetMouseButtonDown(0)) {
            //convert input from screen coords (scren_size in pixel) to transform coordinates
            input_position = Camera.main.ScreenToWorldPoint(Input.mousePosition);
            input_position.z = transform.position.z;
            //log input registered with system timestamp, will be read from android logcat
            print("Input registered " + System.DateTime.UtcNow.ToString("HH:mm:ss.fff"));
        }
    }

    private void FixedUpdate() {
        //move player to new location, if current location != input position
        if (transform.position.x != input_position.x) {
            transform.position = Vector3.MoveTowards(transform.position,new Vector3(input_position.x,transform.position.y,0),move_speed * Time.deltaTime);
        }
    }
}
