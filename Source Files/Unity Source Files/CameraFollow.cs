using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Transform target;

    private void LateUpdate() {
        Vector3 new_position = new Vector3(transform.position.x, target.position.y, transform.position.z);
        transform.position = new_position;
    }
}
